//
//  Rumpelstiltskin.swift
//  Rumpelstiltskin
//
//  Created by Christian Braun on 01.07.19.
//

import Foundation

public typealias NodeKey = String
public typealias NodeValue = String

public protocol ValueBuilder {
    var definitionPattern: String { get }
    var valuePattern: String { get }
    func build(for key: NodeKey, value: NodeValue) -> (definition: String, value: String)
    func applies(to value: NodeValue) -> Bool
}

public struct StringValueBuilder: ValueBuilder {

    public let definitionPattern: String = "public static let {{variableName}} = "
    public let valuePattern: String = "NSLocalizedString(\"{{key}}\", tableName: nil, bundle: Bundle.main, value: \"\", comment: \"\")\n"


    public func build(for key: NodeKey, value: NodeValue) -> (definition: String, value: String) {
        let variableName = key.split(separator: ".").last!
        return (
            definitionPattern
                .replacingOccurrences(of: "{{variableName}}", with: variableName),
            valuePattern
                .replacingOccurrences(of: "{{key}}", with: key))
    }

    public func applies(to value: NodeValue) -> Bool {
        return true
    }
}

public struct FunctionValueBuilder: ValueBuilder {
    public var definitionPattern: String = "public static func {{functionName}}({{functionParams}}) -> String "
    public var valuePattern: String =  """
    {
        return String(format: {{stringValueBuilder}}, {{formatParams}})
    }\n
"""

    public func build(for key: NodeKey, value: NodeValue) -> (definition: String, value: String) {
        let functionName = key.split(separator: ".").last!
        let parameters = createFunctionParameters(fromFormatParameters: formatPlaceholders(from: value))

        let functionParams = parameters.map { nameAndType in
            return "\(nameAndType.name): \(nameAndType.type)"
            }.joined(separator: ", ")

        let formatParams = parameters.map { nameAndType in
            return nameAndType.name
            }.joined(separator: ", ")

        return (
            definitionPattern
                .replacingOccurrences(of: "{{functionName}}", with: functionName)
                .replacingOccurrences(of: "{{functionParams}}", with: functionParams),
            valuePattern
                .replacingOccurrences(
                    of: "{{stringValueBuilder}}",
                    with: Rumpelstiltskin.stringValueBuilder.build(for: key, value: value).value)
             .replacingOccurrences(of: "{{formatParams}}", with: formatParams)
        )
    }

    public func applies(to value: NodeValue) -> Bool {
        return value.range(of: #"%[@df]"#, options: .regularExpression) != nil
    }

    func formatPlaceholders(from string: String) -> [String] {
        let regex = try? NSRegularExpression(pattern: #"%[@df]"#, options: [])
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
            case "%f":
                type = "Float"
            default:
                continue
            }

            result.append(("value\(index)", type))
        }

        return result
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

    public func swiftCode(indentation: Int = 0, combinedKey: String = "") -> String {
        var tempCombinedKey = combinedKey
        tempCombinedKey.append("\(key).")
        if let value = value {
            for valueBuilder in valueBuilderInOrderOfAppliance {
                if valueBuilder.applies(to: value) {
                    let definitionAndValue = valueBuilder.build(for: tempCombinedKey, value: value)
                    return "\(definitionAndValue.definition)\(definitionAndValue.value)"
                }
            }
            return "No ValueBuilder Applied"
        }

        var result = "struct \(key) {\n"
        for reference in references {
            result += "\(String(repeating: "\t", count: indentation + 1))\(reference.value.swiftCode(indentation: indentation + 1, combinedKey: tempCombinedKey))"
        }
        result += "\(String(repeating: "\t", count: indentation))}\n"

        return result
    }
}

public class Rumpelstiltskin {
    public static let stringValueBuilder = StringValueBuilder()
    public static let functionValueBuilder = FunctionValueBuilder()

    public static func extractStructure(from content: String) -> StringNode {
        let lines = content.components(separatedBy: "\n")
        let structure = StringNode(with: "Localization")

        for line in lines {
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
