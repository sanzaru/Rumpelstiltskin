#!/usr/bin/env xcrun -sdk macosx swift
//
//  Rumpelstiltskin.swift
//  Rumpelstiltskin
//
//  Created by Christian Braun on 01.07.19.
//  Copyright KURZ Digital Solutions GmbH & Co. KG
//

import Foundation

public typealias NodeKey = String
public typealias NodeValue = String

//from NSHipster - http://nshipster.com/swift-literal-convertible/
struct Regex {
    let pattern: String
    let options: NSRegularExpression.Options?

    private var matcher: NSRegularExpression? {
        return try? NSRegularExpression(pattern: pattern, options: options ?? [])
    }

    init(pattern: String, options: NSRegularExpression.Options? = nil) {
        self.pattern = pattern
        self.options = options
    }

    func match(string: String, options: NSRegularExpression.MatchingOptions? = nil) -> Bool {
        return self.matcher?.numberOfMatches(in: string, options: options ?? [], range: NSMakeRange(0, string.utf16.count)) != 0
    }
}

protocol RegularExpressionMatchable {
    func match(regex: Regex) -> Bool
}

extension String: RegularExpressionMatchable {
    func match(regex: Regex) -> Bool {
        return regex.match(string: self)
    }
}

func ~=<T: RegularExpressionMatchable>(pattern: Regex, matchable: T) -> Bool {
    return matchable.match(regex: pattern)
}


public protocol ValueBuilder {
    var definitionPattern: String { get }
    var valuePattern: String { get }
    func build(for key: NodeKey, value: NodeValue) -> (definition: String, value: String)
    func applies(to value: NodeValue) -> Bool
}

public struct StringValueBuilder: ValueBuilder, Sendable {
    public let definitionPattern: String = "public static let {{variableName}} = "

    public let valuePattern: String = "NSLocalizedString(\"{{key}}\", tableName: nil, bundle: Bundle.main, value: \"\", comment: \"\")\n"
    public let valuePatternSPM: String = "NSLocalizedString(\"{{key}}\", tableName: nil, bundle: Bundle.module, value: \"\", comment: \"\")\n"

    public func build(for key: NodeKey, value: NodeValue) -> (definition: String, value: String) {
        let variableName = key.split(separator: ".").last!
        let isSPM = CommandLine.arguments.count > 3 && CommandLine.arguments[3] == "SPM"

        return (
            definitionPattern
                .replacingOccurrences(of: "{{variableName}}", with: variableName),

            (isSPM ? valuePatternSPM : valuePattern)
                .replacingOccurrences(of: "{{key}}", with: key))
    }

    public func applies(to value: NodeValue) -> Bool {
        return true
    }
}

public struct FunctionValueBuilder: ValueBuilder, Sendable {
    public var definitionPattern: String = "public static func {{functionName}}({{functionParams}}) -> String"
    public var valuePattern: String =  """
 {
return String(format: {{stringValueBuilder}}, {{formatParams}})
}\n
"""

    public func build(for key: NodeKey, value: NodeValue) -> (definition: String, value: String) {
        let functionName = key.split(separator: ".").last!
        let parameters = createFunctionParameters(fromFormatParameters: formatPlaceholders(from: value))

        var functionParams = [String]()
        for (index, nameAndType) in parameters.enumerated() {
            functionParams.append(index == 0 ?
                "\(nameAndType.name): \(nameAndType.type)" :
             "_ \(nameAndType.name): \(nameAndType.type)")
        }

        let formatParams = parameters.map { nameAndType in
            return nameAndType.name
            }.joined(separator: ", ")

        return (
            definitionPattern
                .replacingOccurrences(of: "{{functionName}}", with: functionName)
                .replacingOccurrences(of: "{{functionParams}}", with: functionParams.joined(separator: ", ")),
            valuePattern
                .replacingOccurrences(
                    of: "{{stringValueBuilder}}",
                    with: Rumpelstiltskin.stringValueBuilder.build(for: key, value: value).value)
             .replacingOccurrences(of: "{{formatParams}}", with: formatParams)
        )
    }

    public func applies(to value: NodeValue) -> Bool {
        return value.range(of: #"%([@df]|(\.\d*f))"#, options: .regularExpression) != nil
    }

    func formatPlaceholders(from string: String) -> [String] {
        let regex = try? NSRegularExpression(pattern: #"%([@df]|(\.\d*f))"#, options: [])
        let results = regex?.matches(
            in: string,
            options: [],
            range: NSRange(string.startIndex..., in: string))

        let formatPlaceholders: [String] = results?.compactMap { result in
            guard let range = Range(result.range, in: string) else { return nil }
            return String(string[range])
        } ?? [String]()

        return formatPlaceholders
    }

    func createFunctionParameters(fromFormatParameters formatParameters: [String]) -> [(name: String, type: String)] {
        var result = [(String, String)]()
        for (index, formatParameter) in formatParameters.enumerated() {
            var type = ""
            switch formatParameter {
            case "%@":
                type = "String"
            case "%d":
                type = "Int"
            case Regex(pattern: "(%(\\.*\\d*f)"):
                type = "Float"
            default:
                continue
            }

            result.append(("value\(index + 1)", type))
        }

        return result
    }
}

public enum IndentationType {
    case spaces(tabSize: Int)
    case tabs

    fileprivate var string: String {
        switch self {
        case .spaces(let tabSize):
            return String(repeating: " ", count: tabSize)
        case .tabs:
            return "\t"
        }
    }
}

public struct Indentation {
    let indentationType: IndentationType

    public init(indentationType: IndentationType) {
        self.indentationType = indentationType
    }

    public func indent(_ value: String) -> String {
        let lines = value.split(separator: "\n")

        var result = [String]()
        var indentationLevel = 0
        for line in lines {
            if line.contains("}") {
                indentationLevel -= 1
            }
            result.append("\(String(repeating: indentationType.string, count: indentationLevel))\(line)")
            if line.contains("{") {
                indentationLevel += 1
            }
        }

        return result.joined(separator: "\n")
    }
}

public class StringNode {
    let key: NodeKey
    var value: NodeValue?
    var references = [NodeValue: StringNode]()

    public var valueBuilderInOrderOfAppliance: [ValueBuilder] = [
        Rumpelstiltskin.functionValueBuilder,
        Rumpelstiltskin.stringValueBuilder]

    init(with key: NodeKey) {
        self.key = key
    }

    public func swiftCode() -> String {
        return """
        // This code was generated by Rumpelstiltskin
        // Do not modify anything by hand and run the main.swift skript instead
        
        import Foundation

        public struct Localizations {
        \(swiftCodeSkipRoot())
        }
        """
    }

    private func swiftCodeSkipRoot() -> String {
        var result = ""
        for reference in references.sorted(by: { a, b -> Bool in
            return a.key < b.key
        }) {
            result += reference.value.swiftCode(combinedKey: "")
        }

        return result
    }

    private func swiftCode(combinedKey: String) -> String {
        var tempCombinedKey = combinedKey
        tempCombinedKey.append("\(key)")
        if let value = value {
            for valueBuilder in valueBuilderInOrderOfAppliance {
                if valueBuilder.applies(to: value) {
                    let definitionAndValue = valueBuilder.build(for: tempCombinedKey, value: value)
                    let baseTranslationComment = "/// Base translation: \(value)"
                    return "\(baseTranslationComment)\n\(definitionAndValue.definition)\(definitionAndValue.value)"
                }
            }
            return "No ValueBuilder applied"
        }
        tempCombinedKey.append(".")

        var result = "struct \(key) {\n"
        for reference in references.sorted(by: { a, b -> Bool in
            return a.key < b.key
        }) {
            result += reference.value.swiftCode(combinedKey: tempCombinedKey)
        }
        result += "}\n"

        return result
    }
}

public class Rumpelstiltskin {
    public static let stringValueBuilder = StringValueBuilder()
    public static let functionValueBuilder = FunctionValueBuilder()

    public static func extractStructure(from content: String) -> StringNode {
        print("Begin extracting structure from Localization file")
        let lines = content.components(separatedBy: "\n")
        let structure = StringNode(with: "")

        var lineInBlockComment = false
        for line in lines {
            // Ignore comments
            if line.starts(with: "/*") {
                lineInBlockComment = true
            }
            if line.contains("*/") {
                lineInBlockComment = false
                continue
            }
            if line.starts(with: "//")
                || lineInBlockComment
                || line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }
            let components = extractComponents(fromLine: line)
            var currentNode = structure

            for component in components.hirarchie {
                let node = StringNode(with: component)
                if let nodeToProcess = currentNode.references[component] {
                    currentNode = nodeToProcess
                } else {
                    currentNode.references[component] = node
                    currentNode = node
                }
            }

            currentNode.value = components.value
        }

        print("Done extracting structure")
        return structure
    }

    static func extractComponents(fromLine line: String) -> (hirarchie: [String], value: String) {
        let parts = line
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .dropLast()
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: ";", with: "")
            .split(separator: "=")

        let firstPart = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let valuePart = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)


        return (firstPart.components(separatedBy: "."), valuePart)
    }
}


func run() throws {
    assert(CommandLine.arguments.count >= 3)
    let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
    let dataAsString = String(data: data, encoding: .utf8)!


    print("Using \(CommandLine.arguments[1]) as Localization File")
    print("Writing to \(CommandLine.arguments[2])")

    let code = Rumpelstiltskin.extractStructure(from: dataAsString).swiftCode()
    let indentedCode = Indentation(indentationType: .spaces(tabSize: 4)).indent(code)

    try indentedCode.data(using: .utf8)?.write(to: URL(string: "file://"+CommandLine.arguments[2])!)
}

try run()
