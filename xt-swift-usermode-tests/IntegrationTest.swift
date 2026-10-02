// TurboAssembler201Tests.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Testing
import Foundation

extension String: @retroactive LocalizedError {
    public var errorDescription: String? { return self }
}

class IntegrationTest {

    let tempDir: String

    init() throws {
        tempDir = "\(NSTemporaryDirectory())\(UUID().uuidString)/"
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true, attributes: nil)
    }

    deinit {
        do {
            try FileManager.default.removeItem(atPath: tempDir)
        } catch {
            // ignore.
        }
    }

    func copy(_ binDir: String, _ binProgram: String) throws {
        let source = "\(projectRootPath())bin/\(binDir)/\(binProgram)"
        let dest = "\(tempDir)\(binProgram)"
        try FileManager.default.copyItem(atPath: source, toPath: dest)
    }

    func write(_ filename: String, _ contents: String) throws {
        let path = "\(tempDir)\(filename)"
        if !FileManager.default.createFile(atPath: path, contents: contents.data(using: .utf8), attributes: nil) {
            throw "Failed to create file: \(path)"
        }
    }

    func execute(_ arguments: [String]) throws -> ExecBinResult {
        let environment = ["XT_EXIT_ON_STDIN": "254", "XT_COMBINE_STDOUT_STDERR": "1"]
        return try xt_swift_usermode_tests.execute("\(projectRootPath())build/xt", arguments, tempDir, environment)
    }

    private func projectRootPath() -> String {
        let currentFileURL = URL(fileURLWithPath: #filePath)
        let rootURL = currentFileURL
            .deletingLastPathComponent() // Removes "Utils.swift"
            .deletingLastPathComponent() // Removes "xt-swift-usermde-tests" folder
        return rootURL.path + "/"
    }
}
