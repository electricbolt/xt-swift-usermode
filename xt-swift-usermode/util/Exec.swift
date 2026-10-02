// Exec.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Foundation

typealias ExecBinResult = (
    exitCode: Int32,
    stdout: String,
    stderr: String
)

func execute(_ path : String, _ arguments: [String], _ workingDirectory: String? = nil,
             _ environment: [String: String]? = nil) throws -> ExecBinResult {

    let task = Process()
    task.launchPath = path
    task.arguments = arguments
    if let workingDirectory {
        task.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
    }
    task.environment = environment

    let stdoutPipe = Pipe()
    task.standardOutput = stdoutPipe
    let stderrPipe = Pipe()
    task.standardError = stderrPipe

    // Buffers protected by a lock since the readabilityHandler callbacks fire on a background queue.
    let lock = NSLock()
    var stdoutData = Data()
    var stderrData = Data()

    stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
       let data = handle.availableData
       if !data.isEmpty {
           lock.lock()
           stdoutData.append(data)
           lock.unlock()
       }
   }

   stderrPipe.fileHandleForReading.readabilityHandler = { handle in
       let data = handle.availableData
       if !data.isEmpty {
           lock.lock()
           stderrData.append(data)
           lock.unlock()
       }
   }

    try task.run()
    task.waitUntilExit()

    // Drain any remaining data and stop the handlers.
    stdoutPipe.fileHandleForReading.readabilityHandler = nil
    stderrPipe.fileHandleForReading.readabilityHandler = nil

    // Grab any last bytes synchronously (readabilityHandler fires asynchronously so there can
    // be a trailing chunk after exit).
    let remainingOut = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    let remainingErr = stderrPipe.fileHandleForReading.readDataToEndOfFile()

    lock.lock()
    stdoutData.append(remainingOut)
    stderrData.append(remainingErr)
    let output = String(data: stdoutData, encoding: .utf8) ?? ""
    let error = String(data: stderrData, encoding: .utf8) ?? ""
    lock.unlock()

    let result = ExecBinResult(
        exitCode: task.terminationStatus,
        stdout: output,
        stderr: error
    )
    return result
}
