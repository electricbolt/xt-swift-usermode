// EndOfMemory.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088

/// EndOfMemory is just that - the last 32 bytes at the end of the 1MB address range. The motherboard BIOS normally occupies this area on a PC. We
/// disallow reading and writing from this memory space to handle errant processes that wouldn't normally be loaded this high.

public class EndOfMemory: MemorySpace {

    public init(_ memory: Memory, _ paragraph: ParagraphAlloc) {
        super.init(memory, UInt16(try! paragraph.alloc(algorithm: .lastFit, sizeInBytes: 32)), 0, 32)

        removePermission()
    }
}
