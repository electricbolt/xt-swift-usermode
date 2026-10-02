// MemoryManager.swift
// XT Copyright © 2026; Electric Bolt Limited.

import XTSwiftCPU8088

public enum MemoryAllocError: Error {
    case invalidSize(Int)                      // sizeInBytes parameter
    case invalidBlock
    case insufficentMemory(Int)                // maximum allocation possible
}

public enum MemoryAllocAlgorithm {
    case firstFit
    case bestFit
    case lastFit
}

/// MS-DOS links `MCB`s together in a single linked list type structure.
///
/// A MCB has the following properties:
/// - type: The first or middle MCB in the chain has a type character of `M`. The last or only memory control block in the chain has a type character of `Z`.
/// - size: The size in paragraphs (a paragraph is 16 bytes) of memory that follows the MCB.
/// - owner: The ID number of the process to which the memory has been allocated (the "owner" process). The ID number is the Program Segment Prefix
/// (PSP), or 0x0000 = if the memory block is available for use.
///
/// The initial state of the MemoryManager is to have one MCB that covers the entire `program` from start `segment` of `size` bytes.

public class MemoryManager {
    
    /// Writes the initial MCB at `program.segment`.
    ///
    /// `type=Z` (last/only), `owner=0` (free), `size=totalParagraphs-1`. Subtracting 1 because the MCB header itself occupies one paragraph.

    public init(_ memory: Memory, _ program: Program) {
        self.memory = memory
        self.owner = 0
        self.program = program

        // Write the initial MCB - a single free block covering the entire program space.
        let paragraphs = UInt16(ParagraphAlloc.toParagraphs(program.size) - 1)
        let mcb = MCB(memory, program.segment)
        mcb.writeType(.last)
        mcb.writeOwner(0)
        mcb.writeSize(paragraphs)
    }

    /// Set the process `owner` of the allocated memory - the segment of the program segment prefix.

    public func setOwner(owner: UInt16) {
        self.owner = owner
    }

    /// Attempts to allocate a block of memory `sizeInBytes` (rounded up to the nearest paragraph) using algorithm provided.
    ///
    /// Walks the chain from `program.segment`, collects free blocks, applies the algorithm, then either claims the block as-is (exact fit) or splits it — the
    /// remainder gets a new MCB written immediately after the allocated region, preserving the `Z` type if the original block was the last in the chain.
    ///
    /// - Parameter algorithm which allocation algorithm to use
    /// - Parameter sizeInBytes the number of bytes to allocate excluding the memory control block
    /// - Returns memory control block
    /// - Throws .invalidBlock if the memory control block has been destroyed
    /// - Throws .invalidSize if the requested sizeInBytes is out of range
    /// - Throws .insufficientMemory if the requested expansion could not be made. The associated value is the largest possible allocation.

    public func alloc(algorithm: MemoryAllocAlgorithm, sizeInBytes: Int) throws -> MCB? {
        if sizeInBytes < 0 {
            throw MemoryAllocError.invalidSize(sizeInBytes)
        }

        let sizeInParagraphs = ParagraphAlloc.toParagraphs(sizeInBytes)

        // Walk the MCB chain collecting free blocks (owner is 0)
        typealias FreeBlock = (segment: UInt16, size: UInt16)
        var freeBlocks = [FreeBlock]()
        var segment = program.segment
        while true {
            let mcb = MCB(memory, segment)
            try check(mcb: mcb)
            let size = mcb.readSize()
            if mcb.readOwner() == 0 {
                freeBlocks.append((segment: segment, size: size))
            }
            guard mcb.readType() == .valid else { break }
            segment = segment &+ UInt16(size + 1)
        }

        let candidates = freeBlocks.filter { $0.size >= sizeInParagraphs }
        if sizeInBytes == 0 || candidates.isEmpty {
            let largest = Int(freeBlocks.map { $0.size }.max() ?? 0)
            throw MemoryAllocError.insufficentMemory(largest * 16)
        }

        let selected: FreeBlock
        switch algorithm {
            case .firstFit: selected = candidates.first!
            case .bestFit: selected = candidates.min(by: { $0.size < $1.size })!
            case .lastFit: selected = candidates.last!
        }

        let mcb = MCB(memory, selected.segment)

        if selected.size > sizeInParagraphs {
            // Split: carve off the remainder into a new MCB directly after the allocated block.
            // The new MCB header consumes one paragraph, so remainder size = original - needed - 1.
            let newSegment = selected.segment &+ UInt16(sizeInParagraphs + 1)
            let remainder = MCB(memory, newSegment)
            remainder.writeType(mcb.readType()!)   // Preserve Z if this was the last block.
            remainder.writeOwner(0)
            remainder.writeSize(UInt16(Int(selected.size) - sizeInParagraphs - 1))
            mcb.writeType(.valid)
            mcb.writeSize(UInt16(sizeInParagraphs))
        }

        mcb.writeOwner(owner)
        return mcb
    }

    /// Frees an existing block of memory `sizeInBytes` (rounded up to the nearest paragraph).
    ///
    /// - Parameter mcb the memory control block of the memory to free
    /// - Throws .invalidBlock if the memory control block has been destroyed
    /// - Throws .invalidSize if the requested sizeInBytes is out of range

    public func free(mcb: MCB) throws {
        try check(mcb: mcb)
        mcb.writeOwner(0)

        // Coalesce: walk the chain from the start and merge consecutive free blocks. When two adjacent free blocks are
        // found, absorb the next into the current (adding next.size + 1 to current.size, inheriting next's type), then
        // re-check without advancing so chains of three or more free blocks collapse in one pass.
        var segment = program.segment
        while true {
            let current = MCB(memory, segment)
            try check(mcb: current)
            let size = current.readSize()
            guard current.readOwner() == 0 else {
                guard current.readType() == .valid else { break }
                segment = segment &+ size &+ 1
                continue
            }
            guard current.readType() == .valid else { break }
            let nextSegment = segment &+ size &+ 1
            let next = MCB(memory, nextSegment)
            if next.readOwner() == 0 {
                current.writeType(next.readType()!)
                current.writeSize(size &+ 1 &+ next.readSize())
                // Don't advance: re-check in case the absorbed block's successor is also free.
            } else {
                segment = nextSegment
            }
        }
    }

    /// Resizes an existing block of memory to `newSizeInBytes` (rounded up to the nearest paragraph.
    ///
    /// The block of memory can be shrunk or expanded (if space allows).
    ///
    /// - Parameter mcb the memory control block of the memory to resize
    /// - Throws .invalidBlock if the memory control block has been destroyed
    /// - Throws .invalidSize if the requested sizeInBytes is out of range
    /// - Throws .insufficientMemory if the requested expansion could not be made. The associated value is the largest possible allocation

    public func resize(mcb: MCB, newSizeInBytes: Int) throws {
        try check(mcb: mcb)
        if newSizeInBytes <= 0 {
            throw MemoryAllocError.invalidSize(newSizeInBytes)
        }
        let newSizeInParagraphs = ParagraphAlloc.toParagraphs(newSizeInBytes)
        let currentSize = Int(mcb.readSize())

        if newSizeInParagraphs == currentSize {
            return
        } else if newSizeInParagraphs < currentSize {
            // Shrink - place a new free MCB at mcb.segment + needed + 1 for the released paragraphs. If the block that
            // originally followed is also free, merge it into the remainder in one step (preserving its type so the Z
            // marker propagates correctly).
            let freed = currentSize - newSizeInParagraphs - 1
            let remainderSegment = mcb.segment &+ UInt16(newSizeInParagraphs + 1)
            let remainder = MCB(memory, remainderSegment)

            // If the block that immediately follows is free, merge it into the remainder.
            if mcb.readType() == .valid {
                let nextSegment = mcb.segment &+ UInt16(currentSize + 1)
                let next = MCB(memory, nextSegment)
                try check(mcb: next)
                if next.readOwner() == 0 {
                    remainder.writeType(next.readType()!)
                    remainder.writeSize(UInt16(freed + 1 + Int(next.readSize())))
                    remainder.writeOwner(0)
                    mcb.writeType(.valid)
                    mcb.writeSize(UInt16(newSizeInParagraphs))
                    return
                }
            }

            remainder.writeType(mcb.readType()!)   // preserve Z if this was the last block
            remainder.writeSize(UInt16(freed))
            remainder.writeOwner(0)
            mcb.writeType(.valid)
            mcb.writeSize(UInt16(newSizeInParagraphs))
        } else {
            // Expand: absorb paragraphs from the immediately following free MCB. available = currentSize + 1 (next MCB
            // header) + nextSize. The +1 accounts for absorbing the next MCB's own header paragraph)
            guard mcb.readType() == .valid else {
                throw MemoryAllocError.insufficentMemory(0)
            }
            let nextSegment = mcb.segment &+ UInt16(currentSize + 1)
            let next = MCB(memory, nextSegment)
            try check(mcb: next)
            guard next.readOwner() == 0 else {
                throw MemoryAllocError.insufficentMemory(0)
            }
            let nextSize = Int(next.readSize())
            let available = currentSize + 1 + nextSize
            guard newSizeInParagraphs <= available else {
                // Throws .insufficentMemory if the gap isn't large enough, if there's no adjacent free block at all.
                throw MemoryAllocError.insufficentMemory(available * 16)
            }
            if newSizeInParagraphs == available {
                // Exact fit: absorb all of next (header + data).
                mcb.writeType(next.readType()!)
                mcb.writeSize(UInt16(newSizeInParagraphs))
            } else {
                // Partial absorption: create a new free MCB for the unused remainder.
                let newNextSegment = mcb.segment &+ UInt16(newSizeInParagraphs + 1)
                let newNext = MCB(memory, newNextSegment)
                newNext.writeType(next.readType()!)
                newNext.writeOwner(0)
                newNext.writeSize(UInt16(available - newSizeInParagraphs - 1))
                mcb.writeSize(UInt16(newSizeInParagraphs))
                // mcb.type stays .valid — newNext is the new successor
            }
        }
    }

    // MARK: - Internal

    private var memory: Memory
    private var owner: UInt16
    private var program: Program

    private func check(mcb: MCB) throws {
        guard mcb.readType() == .valid || mcb.readType() == .last else {
            throw MemoryAllocError.invalidBlock
        }
        guard mcb.readOwner() == 0 || mcb.readOwner() == owner else {
            throw MemoryAllocError.invalidBlock
        }
    }
}
