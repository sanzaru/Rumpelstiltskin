//  Copyright KURZ Digital Solutions GmbH & Co. KG

import PackagePlugin
import Foundation

@main
struct RumpelstiltskinBuildPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        guard let target = target.sourceModule else { return [] }
        guard let file = target.sourceFiles.filter({ $0.path.extension == "strings" }).first else { return [] }

        let outputDir = context.pluginWorkDirectory.appending("Localizations.swift")

        return [.buildCommand(
            displayName: "Running Rumpelstiltskin Build Plugin",
            executable: try context.tool(named: "RumpelstiltskinBin").path,
            arguments: [ "", file.path.string, outputDir, "SPM" ],
            outputFiles: [outputDir])
        ]
    }
}

#if canImport(XcodeProjectPlugin)

import XcodeProjectPlugin

extension RumpelstiltskinBuildPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(
        context: XcodePluginContext,
        target: XcodeTarget
    ) throws -> [Command] {
        let outputDir = context.pluginWorkDirectory.appending("Localizations.swift")

        return [.buildCommand(
            displayName: "Running Rumpelstiltskin Build Plugin (xCode)",
            executable: try context.tool(named: "RumpelstiltskinBin").path,
            arguments: [ inputFiles(target: target), outputDir ],
            outputFiles: [outputDir]
        )]
    }

    private func inputFiles(target: XcodeTarget) -> String {
        if let files = target.inputFiles.filter({ $0.type == .resource && $0.path.extension == "strings" }).first {
            return files.path.description
        }

        return ""
    }
}
#endif
