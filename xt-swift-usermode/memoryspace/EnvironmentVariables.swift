// EnvironmentVariables.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088

/// Environment variables for the current MS-DOS program being executed.

public class EnvironmentVariables: MemorySpace {

    public init(_ memory: Memory, _ paragraph: ParagraphAlloc) {
        super.init(memory, paragraph, 256)
        self.address = SegOfs(segment, 0)
    }

    public func writeVariable(_ key: String, _ value: String) {
        writeString(key)
        writeString("=")
        writeString(value)
        writeByte(0x00)                // add null terminator character.
    }

    public func writeExecutablePath(_ path: String) {
        // Add second null terminator character indicating end of environment variables.
        writeByte(0x00)

        // Executable path.
        writeWord(0x0001)              // number of items following - always 0x0001.
        writeString(path)
        writeByte(0x00)                // add null terminator character.

        // Add second null terminator character indicating end of executable path.
        writeByte(0x00)
    }

    // MARK: - Internal

    private var address: SegOfs!

    private func writeString(_ str: String) {
        for char in str {
            writeByte(char.asciiValue!)
        }
    }

    private func writeByte(_ b: UInt8) {
        memory.setByte(address, b)
        address.increment()
    }

    private func writeWord(_ w: UInt16) {
        memory.setWord(address, w)
        address.addOffset(2)
    }
}
