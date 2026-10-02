// InterruptVectorTable.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088

/// The interrupt vector table of 256 x Seg:Ofs addresses. Always located at 0000:0000.

public class InterruptVectorTable: MemorySpace {

    public init(_ memory: Memory, _ paragraph: ParagraphAlloc) {
        super.init(memory, paragraph, 1024)
    }
}
