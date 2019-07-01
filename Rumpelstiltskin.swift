//
//  Rumpelstiltskin.swift
//  Rumpelstiltskin
//
//  Created by Christian Braun on 01.07.19.
//

import Foundation

typealias NodeKey = String
typealias NodeValue = String

public class StringNode: CustomStringConvertible {
    let key: NodeKey
    var value: NodeValue?
    var references = [NodeValue: StringNode]()

    init(with key: NodeKey) {
        self.key = key
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
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: ";", with: "")
            .split(separator: "=")

        let firstPart = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let valuePart = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)


        return (firstPart.components(separatedBy: "."), valuePart)
    }
}
