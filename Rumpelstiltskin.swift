//
//  Rumpelstiltskin.swift
//  Rumpelstiltskin
//
//  Created by Christian Braun on 01.07.19.
//

import Foundation

typealias NodeKey = String
public typealias NodeValue = String

public protocol ValueBuilder {
    var pattern: String { get }
    func build(for value: NodeValue) -> String
}

public struct StringValueBuilder: ValueBuilder {
    public var pattern = "NSLocalizedString(\"{{value}}\", tableName: nil, bundle: Bundle.main, value: \"\", comment: \"\")"


    public func build(for value: NodeValue) -> String {
        return pattern.replacingOccurrences(of: "{{value}}", with: value)
    }
}

public struct FunctionValueBuilder: ValueBuilder {
    public var pattern =  """
public static func NotificationWithFailures({{functionParams}}) -> String {
        return String(format: {{stringValueBuilder}}, {{formatParams}})
    }
"""

    public func build(for value: NodeValue) -> String {
        let parameters = createFunctionParameters(fromFormatParameters: formatPlaceholders(from: value))

        let functionParams = parameters.map { nameAndType in
            return "\(nameAndType.name): \(nameAndType.type)"
            }.joined(separator: ",")

        let formatParams = parameters.map { nameAndType in
            return nameAndType.name
            }.joined(separator: ",")

        var result = pattern
            .replacingOccurrences(
                of: "{{stringValueBuilder}}",
                with: Rumpelstiltskin.stringValueBuilder.build(for: value))
            .replacingOccurrences(of: "{{functionParams}}", with: functionParams)
            .replacingOccurrences(of: "{{formatParams}}", with: formatParams)

        return result
    }

    func formatPlaceholders(from string: String) -> [String] {
        let regex = try? NSRegularExpression(pattern: "#%[@df]", options: [])
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

public class StringNode: CustomStringConvertible {
    let key: NodeKey
    var value: NodeValue?
    var references = [NodeValue: StringNode]()

    init(with key: NodeKey) {
        self.key = key
    }

    public func swiftCode(indentation: Int = 0) -> String {
        if let value = value {
            return "let \(key) = \"\(value)\"\n"
        }

        var result = "struct \(key) {\n"
        for reference in references {
            result += "\(String(repeating: "\t", count: indentation + 1))\(reference.value.swiftCode(indentation: indentation + 1))"
        }
        result += "\(String(repeating: "\t", count: indentation))}\n"

        return result
    }

    public var description: String {
        if let value = value {
            return " = \(value)"
        }
        var result = "\(key)"
        for reference in references {
            result += "-> \(reference.value)"
            result += "\n"
        }

        return result
    }
}

public class Rumpelstiltskin {
    public static let stringValueBuilder = StringValueBuilder()

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
