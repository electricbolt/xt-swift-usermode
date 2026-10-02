// MCB.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088

/// MS-DOS Memory Control Block (also known as a memory arena). See `MemoryManager` class to allocate, resize and free
/// blocks of memory.

public class MCB: MemorySpace {

    public static let allocationSize = MemoryLayout<_MCB>.size

    public enum MCBType: Character {
        case valid = "M"            // the first or middle memory control block in the chain
        case last = "Z"             // the last or only memory control block in the chain
    }

    public init(_ memory: Memory, _ segment: UInt16) {
        assert(MemoryLayout<_MCB>.size == 16)

        super.init(memory, segment, 0, MCB.allocationSize)
    }

    /// The identation level of the name of the memory space output by the `dump` method.
    ///
    /// Only the `MCB` and `PSP` are indented. All other memory spaces use the default 0.

    override open func dumpIndent() -> Int {
        return 2
    }

    /// `M` for first & middle MCBs in the chain. `Z` for the last MCB in the chain.

    public func writeType(_ type: MCBType) {
        setByte(ofs.type, type.rawValue.asciiValue!)
    }

    /// The ID number of the process to which the block has been allocated (the "owner" process). The ID number is the Program Segment Prefix (PSP).
    /// If 0x0000 = if the memory block is available for use.

    public func writeOwner(_ owner: UInt16) {
        setWord(ofs.owner, owner)
    }

    /// The size in paragraphs of the memory block following this MCB.

    public func writeSize(_ size: UInt16) {
        setWord(ofs.size, size)
    }

    /// `M` for first & middle MCBs in the chain. `Z` for the last MCB in the chain.

    public func readType() -> MCBType? {
        return MCBType(rawValue: Character(Unicode.Scalar(readByte(ofs.type))))
    }

    /// The ID number of the process to which the block has been allocated. 0x0000 = free.

    public func readOwner() -> UInt16 {
        return readWord(ofs.owner)
    }

    /// The size in paragraphs of the memory block following this MCB.

    public func readSize() -> UInt16 {
        return readWord(ofs.size)
    }

    public func writeProgram(_ program: String) {
        var i = 0
        while i < min(8, program.utf8.count) {
            setByte(ofs.program + i, program.utf8[program.index(program.startIndex, offsetBy: i)])
            i += 1
        }
        if i < 8 {
            setByte(ofs.program + i, 0x00) // add null terminator character.
        }
    }

    // MARK: - Internal

    private struct Ofs {
        let type = MemoryLayout<_MCB>.offset(of: \.type)!
        let owner = MemoryLayout<_MCB>.offset(of: \.owner)!
        let size = MemoryLayout<_MCB>.offset(of: \.size)!
        let program = MemoryLayout<_MCB>.offset(of: \.program)!
    }
    private let ofs = Ofs()
}
