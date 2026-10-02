// Program.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088

/// The remaining "free" memory space that is available to load MS-DOS programs (after the `InterruptVectorTable`, `BIOSDataArea`,
/// `DOSVariables` ... have been allocated).

public class Program: MemorySpace {

    public init(_ memory: Memory, _ paragraph: ParagraphAlloc) {
        super.init(memory, paragraph, paragraph.totalFreeSizeInBytes())
    }
}
