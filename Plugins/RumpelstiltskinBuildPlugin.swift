import PackagePlugin
import Foundation

@main
struct RumpelstiltskinBuildPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        // This example configures `sometool` to write to a "GeneratedFiles" directory in
        // the plugin work directory (which is unique for each plugin and target).
        let outputDir = context.pluginWorkDirectory.appending("GeneratedFiles")
        try FileManager.default.createDirectory(atPath: outputDir.string,
                                                withIntermediateDirectories: true)

        // Return a command to run `sometool` as a prebuild command. It will be run before
        // every build and generates source files into an output directory provided by the
        // build context.
        return [.buildCommand(
            displayName: "Running Rumpelstiltskin",
            executable: try context.tool(named: "RumpelstiltskinBin").path,
            arguments: [ "--verbose", "--outdir", outputDir ]
        )]
    }
}

#if canImport(XcodeProjectPlugin)

import XcodeProjectPlugin

extension RumpelstiltskinBuildPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(
        context: XcodePluginContext,
        target: XcodeTarget
    ) throws -> [Command] {
        let outputDir = context.xcodeProject.directory.appending(["Localizations.swift"])

        print("=== \(outputDir.description) ===")

        return [.buildCommand(
            displayName: "Running Rumpelstiltskin",
            executable: try context.tool(named: "RumpelstiltskinBin").path,
            arguments: [ inputFiles(target: target), outputDir ]
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
