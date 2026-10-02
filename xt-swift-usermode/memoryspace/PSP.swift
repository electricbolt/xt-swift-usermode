// PSP.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088

/// MS-DOS Program Segment Prefix. A 256 byte area of memory directly before the program code.

public class PSP: MemorySpace {

    public static let allocationSize = MemoryLayout<_PSP>.size

    public init(_ memory: Memory, _ segment: UInt16) {
        assert(MemoryLayout<_PSP>.size == 256)
        assert(ofs.nextSeg == 2)
        assert(ofs.commandLineLength == 128)

        super.init(memory, segment, 0, PSP.allocationSize)

        setByte(ofs.int20, 0xCD)            // INT instruction.
        setByte(ofs.int20 + 1, 0x20)        // 20 value.

        setByte(ofs.int21retf, 0xCD)       // INT instruction.
        setByte(ofs.int21retf + 1, 0x21)   // 21 value.
        setByte(ofs.int21retf + 2, 0xCB)   // RETF instruction.
    }

    /// The identation level of the name of the memory space output by the `dump` method.
    ///
    /// Only the `MCB` and `PSP` are indented. All other memory spaces use the default 0.

    override open func dumpIndent() -> Int {
        return 2
    }

    public func writeNextSegment(_ segment: UInt16) {
        setWord(ofs.nextSeg, segment)
    }

    public func writeEnvironment(_ segment: UInt16) {
        setWord(ofs.environmentSeg, segment)
    }

    public func writeFilename(_ fcb: Int, _ drive: Character, _ file: String) {
        var filename = ""
        var ext = ""
        if let dotIndex = file.firstIndex(of: ".") {
            filename = String(file[..<dotIndex])
            ext = String(file[file.index(after: dotIndex)...])
        } else {
            filename = file
        }
        if filename.count > 8 {
            filename = String(filename.prefix(8))
        }
        if ext.count > 3 {
            ext = String(ext.prefix(3))
        }
        if filename.count < 8 {
            filename = filename + String(repeating: " ", count: 8 - filename.count)
        }
        if ext.count < 3 {
            ext = ext + String(repeating: " ", count: 3 - ext.count)
        }
        var offset = (fcb == 1 ? ofs.fcb1 : ofs.fcb2)
        if !file.isEmpty {
            setByte(offset, UInt8(drive.asciiValue! - Character("A").asciiValue!))
        }
        offset += 1
        for char in filename {
            setByte(offset, char.asciiValue!)
            offset += 1
        }
        for char in ext {
            setByte(offset, char.asciiValue!)
            offset += 1
        }
    }

    public func writeCommandLine(_ commandLine: String) {
        var commandLine = commandLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if !commandLine.isEmpty {
            commandLine = " " + commandLine
        }
        if commandLine.count > 127 {
            preconditionFailure("Command line length exceeds 127")
        }
        setByte(ofs.commandLineLength, UInt8(commandLine.count))
        for (i, char) in commandLine.enumerated() {
            setByte(ofs.commandLine + i, char.asciiValue!)
        }
        setByte(ofs.commandLine + commandLine.count, 0x0D)
    }

    // MARK: - Internal

    private struct Ofs {
        let int20 = MemoryLayout<_PSP>.offset(of: \.int20)!
        let int21retf = MemoryLayout<_PSP>.offset(of: \.int21retf)!
        let nextSeg = MemoryLayout<_PSP>.offset(of: \.nextSeg)!
        let environmentSeg = MemoryLayout<_PSP>.offset(of: \.environmentSeg)!
        let fcb1 = MemoryLayout<_PSP>.offset(of: \.fcb1)!
        let fcb2 = MemoryLayout<_PSP>.offset(of: \.fcb2)!
        let commandLineLength = MemoryLayout<_PSP>.offset(of: \.commandLineLength)!
        let commandLine = MemoryLayout<_PSP>.offset(of: \.commandLine)!
    }
    private let ofs = Ofs()
}
