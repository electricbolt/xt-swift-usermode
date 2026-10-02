// ParagraphAlloc.swift
// XT Copyright © 2026; Electric Bolt Limited.

public enum ParagraphAllocError: Error {
    case invalidSize(Int)                      // sizeInBytes parameter
    case invalidBlock
    case insufficentMemory(Int)                // maximum allocation possible
}

public enum ParagraphAllocAlgorithm {
    case firstFit
    case bestFit
    case lastFit
}

/// Allocation of memory in the 20-bit address space is broken down into 16 byte paragraphs.

public class ParagraphAlloc {
    
    @inlinable
    public static func toParagraphs(_ sizeInBytes: Int) -> Int {
        return sizeInBytes / 16 + (sizeInBytes % 16 == 0 ? 0 : 1)
    }

    /// Attempts to allocate a block of memory `sizeInBytes` (rounded up to the nearest paragraph) using algorithm provided.
    ///
    /// - Parameter from: start searching for block of memory from this paragraph
    /// - Parameter algorithm: which allocation algorithm to use
    /// - Parameter sizeInBytes: the number of bytes to allocate
    /// - Returns first paragraph (interchangable as a Segment)
    /// - Throws `.invalidSize` if the requested `sizeInBytes` is out of range
    /// - Throws `.insufficientMemory` if the requested expansion could not be made. The associated value is the largest possible allocation

    public func alloc(from: Int = 0, algorithm: ParagraphAllocAlgorithm, sizeInBytes: Int) throws -> Int {
        if sizeInBytes <= 0 || sizeInBytes > maxAddress {
            throw ParagraphAllocError.invalidSize(sizeInBytes)
        }
        let paragraphs = ParagraphAlloc.toParagraphs(sizeInBytes)
        let block = switch algorithm {
            case .firstFit:
                storage.firstBlock(index: from, count: paragraphs)
            case .bestFit:
                storage.nearestMatchingBlock(index: from, count: paragraphs)
            case .lastFit:
                storage.lastBlock(index: from, count: paragraphs)
        }
        if let block = block {
            storage.applyBlock(index: block.index, count: paragraphs, value: true)
            return block.index
        }
        let blocks = storage.allBlocks(index: from, minimumCount: 1, sortBy: .largest)
        throw ParagraphAllocError.insufficentMemory(blocks.isEmpty ? 0 : blocks[0].count * 16)
    }

    /// Frees an existing block of memory `sizeInBytes` (rounded up to the nearest paragraph).
    ///
    /// - Parameter from: start paragraph of the existing block of memory
    /// - Parameter sizeInBytes: the number of bytes to free
    /// - Throws `.invalidSize` if the requested sizeInBytes is out of range

    public func free(from: Int, sizeInBytes: Int) throws {
        if sizeInBytes <= 0 || sizeInBytes > maxAddress {
            throw ParagraphAllocError.invalidSize(sizeInBytes)
        }
        let paragraphs = ParagraphAlloc.toParagraphs(sizeInBytes)
        storage.applyBlock(index: from, count: paragraphs, value: false)
    }

    /// Resizes an existing block of memory. The block of memory can be shrunk or expanded (if space allows).
    ///
    /// - Parameter from: start paragraph of the existing block of memory
    /// - Parameter oldSizeInBytes: the number of bytes in the current block of memory
    /// - Parameter newSizeInBytes: the number of bytes in the requested block of memory
    /// - Throws `.invalidSize` if the requested sizeInBytes is out of range
    /// - Throws `.insufficientMemory` if the requested expansion could not be made. The associated value is the largest possible allocation

    public func resize(from: Int, oldSizeInBytes: Int, newSizeInBytes: Int) throws {
        if oldSizeInBytes <= 0 || oldSizeInBytes > maxAddress {
            throw ParagraphAllocError.invalidSize(oldSizeInBytes)
        }
        if newSizeInBytes <= 0 || newSizeInBytes > maxAddress {
            throw ParagraphAllocError.invalidSize(newSizeInBytes)
        }
        let oldParagraphs = ParagraphAlloc.toParagraphs(oldSizeInBytes)
        let newParagraphs = ParagraphAlloc.toParagraphs(newSizeInBytes)
        if oldParagraphs == newParagraphs {
            return
        } else if oldParagraphs > newParagraphs {
            // Shrink memory in place
            storage.applyBlock(index: from + newParagraphs, count: oldParagraphs - newParagraphs, value: false)
            return
        } else {
            // Expand memory in place
            if let block = storage.firstBlock(index: from, count: newParagraphs - oldParagraphs) {
                if block.index == from + oldParagraphs {
                    storage.applyBlock(index: block.index, count: newParagraphs - oldParagraphs, value: true)
                    return
                }
            }
            // Can't expand, calculate size of free block directly after the current block.
            if let block = storage.firstBlock(index: from, count: 0) {
                if block.index == from + oldParagraphs {
                    throw ParagraphAllocError.insufficentMemory(block.count * 16)
                }
            }
            throw ParagraphAllocError.insufficentMemory(0)
        }
    }

    public func totalFreeSizeInBytes() -> Int {
        return (storage.allBlocks(minimumCount: 1, sortBy: .largest).reduce(0) { $0 + $1.count }) * 16
    }

    // MARK: - Internal

    private let maxAddress = 1_048_576
    private let storage = BitArray(count: 65536)
}
