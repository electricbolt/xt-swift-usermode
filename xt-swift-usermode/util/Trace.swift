// Trace.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088

public class Trace {

    public init(_ cpu: CPU, _ traceCPU: Bool, _ traceInterrupt: Bool, _ traceFile: String) {
        self.cpu = cpu
        self.traceCPU = traceCPU
        self.traceInterrupt = traceInterrupt
        if traceCPU || traceInterrupt {
            FileManager.default.createFile(atPath: traceFile, contents: nil)
            guard let handle = FileHandle(forWritingAtPath: traceFile) else {
                print(ProcessInfo.processInfo.arguments[0] + ": error opening trace file", to: &stderr)
                exit(255)
            }
            self.traceWriter = handle
        }
    }

    deinit {
        traceWriter?.closeFile()
    }

    public func fetched8(_ value: UInt8, _ instructionCount: UInt64) {
        if traceCPU {
            let s = String(format: "%-10llu   %02X ", instructionCount, value) + cpu.reg.description + "\n"
            traceWriter?.write(s.data(using: .utf8)!)
        }
    }

    public func fetched16(_ value: UInt16, _ instructionCount: UInt64) {
        if traceCPU {
            let s = String(format: "%-10llu %04X ", instructionCount, value) + cpu.reg.description + "\n"
            traceWriter?.write(s.data(using: .utf8)!)
        }
    }

    public func interrupt(_ message: String) {
        if traceInterrupt {
            traceWriter?.write((message + "\n").data(using: .utf8)!)
        }
    }

    public func log(_ message: String) {
        if traceCPU || traceInterrupt {
            traceWriter?.write((message + "\n").data(using: .utf8)!)
        }
    }

    public func flush() {
        traceWriter?.synchronizeFile()
    }

    public func isTracing() -> Bool {
        return traceCPU || traceInterrupt
    }

    // MARK: - Internal

    private let cpu: CPU
    private let traceCPU: Bool
    private let traceInterrupt: Bool
    private var traceWriter: FileHandle?
}
