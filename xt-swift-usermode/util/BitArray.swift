// BitArray.swift
// XT Copyright © 2026; Electric Bolt Limited.

/// A mutable array of zero and ones with functionality to find contiguous blocks of zeros.

public class BitArray {

    public struct Block {
        let index: Int
        let count: Int
    }

    public enum SortBy {
        case largest
        case smallest
    }

    public init(count: Int) {
        let wordCount = (count + 63) / 64
        let pointer = UnsafeMutablePointer<UInt64>.allocate(capacity: wordCount)
        pointer.initialize(repeating: 0, count: wordCount)
        self.storageCount = count
        self.storage = UnsafeMutableBufferPointer(start: pointer, count: wordCount)
    }

    /// Gets or sets the bit at `index` in the underlying storage.

    public subscript(index: Int) -> Bool {
        get {
            let word = index / 64
            let bit = index % 64
            return (storage[word] & (1 << UInt64(bit))) != 0
        }
        set {
            let word = index / 64
            let bit = index % 64
            if newValue {
                storage[word] |= (1 << UInt64(bit))
            } else {
                storage[word] &= ~(1 << UInt64(bit))
            }
        }
    }

    /// Apply either zero or one to the underlying storage from  `index..<index+count`.
    ///
    /// - Parameter from: index of the first bit to set
    /// - Parameter count: number of bits to set
    /// - Parameter value: true to set one bit, false to set zero bit

    public func applyBlock(index: Int, count: Int, value: Bool) {
        for i in index..<(index + count) {
            self[i] = value
        }
    }

    /// Finds the first contiguous block of `count` zeros in the array (from left to right).
    ///
    /// - Parameter offset: starting index (from the left). Defaults to 0
    /// - Parameter count: contiguous number of zeros to find. If 0, then will find the first block of any size
    /// - Returns `Block` with left `offset` and `count` of zeros, or `nil` if not found

    public func firstBlock(index: Int = 0, count: Int) -> Block? {
        // Example: 101001000110 offset=4, count=2, result=6.
        //              O R
        var blockStart = -1
        var blockCount = 0
        for i in index...storageCount - 1 {
            let value = self[i]
            if value == false {
                if blockStart == -1 {
                    blockStart = i
                }
                blockCount += 1
                if count > 0 && blockCount == count {
                    return Block(index: blockStart, count: blockCount)
                }
            } else {
                if count == 0 && blockStart >= 0 {
                    return Block(index: blockStart, count: blockCount)
                }
                blockStart = -1
                blockCount = 0
            }
        }
        if count == 0 {
            return blockCount != 0 ? Block(index: blockStart, count: blockCount) : nil
        } else {
            return nil
        }
    }

    /// Finds the all contiguous block of at least `minimumCount` zeros in the array.
    ///
    /// - Parameter offset: starting index (from the left). Defaults to 0
    /// - Parameter minimumCount: minimum contiguous number of zeros to find, and add into the resulting array
    /// - Parameter sortBy: `.largest` = sort by largest to smallest blocks. `.smallest` = sort by smallest to largest blocks
    /// - Returns array of `Block` structs or nil if none found

    public func allBlocks(index: Int = 0, minimumCount: Int, sortBy: SortBy) -> [Block] {
        // Example: 101000100110 results = (1,1) (3,3) (7,2) (9,1)
        //           A B   C   D            A     B     C     D
        var blockStart = -1
        var blockCount = 0
        var runs = [Block]()
        for i in index...storageCount - 1 {
            let value = self[i]
            if value == false {
                if blockStart == -1 {
                    blockStart = i
                }
                blockCount += 1
            } else {
                if blockStart != -1 && blockCount >= minimumCount {
                    runs.append(Block(index: blockStart, count: blockCount))
                }
                blockStart = -1
                blockCount = 0
            }
        }
        if blockStart != -1 && blockCount >= minimumCount {
            runs.append(Block(index: blockStart, count: blockCount))
        }
        runs.sort { a, b in
            if a.count != b.count {
                if sortBy == .smallest {
                    return a.count < b.count
                } else {
                    return a.count > b.count
                }
            }
            return a.index < b.index
        }
        return runs
    }

    /// Finds the best (least fragmentation) contiguous block of `count` zeros in the array.
    ///
    /// - Parameter index: starting index (from the left). Defaults to 0
    /// - Parameter count: contiguous number of zeros to find
    /// - Returns `Block` with left offset and `count` of zeros, or nil if not found

    public func nearestMatchingBlock(index: Int = 0, count: Int) -> Block? {
        // Example: 101000100110 offset=0, count=2, result=7.
        //          O      R
        let runs = allBlocks(index: index, minimumCount: count, sortBy: .smallest)
        if !runs.isEmpty {
            let block = runs[0]
            return Block(index: block.index, count: count)
        } else {
            return nil
        }
    }

    /// Finds the last contiguous block of `count` zeros in the array (from right to left)
    ///
    /// - Parameter index: starting index (from the right). Defaults to 0
    /// - Parameter count: contiguous number of zeros to find
    /// - Returns `Block` with left offset and `count` of zeros, or nil if not found

    public func lastBlock(index: Int = 0, count: Int) -> Block? {
        // Example: 101000100110 offset=1, count=3, result=7.
        //              R     O
        let from = storageCount - 1 - index
        var blockStart = -1
        var blockCount = 0
        for i in (0...from).reversed() {
            let value = self[i]
            if value == false {
                if blockStart == -1 {
                    blockStart = i
                }
                blockCount += 1
                if blockCount == count {
                    return Block(index: blockStart - count + 1, count: blockCount)
                }
            } else {
                blockStart = -1
                blockCount = 0
            }
        }
        return nil
    }

    // MARK: - Internal

    private var storageCount: Int
    private let storage: UnsafeMutableBufferPointer<UInt64>

    /// For unit tests - allows the bits to be set from a String representation. e.g. "1000111010".

    internal func storage(fromString str: String) {
        assert(str.count == storageCount)
        for i in 0..<str.count {
            self[i] = str[i] == "1"
        }
    }

    /// For unit tests - allows the bits to be returned in a String representation. e.g. "1000111010".

    internal func storageToString() -> String {
        var buf = ""
        for i in 0..<storageCount {
            buf.append(self[i] ? "1" : "0")
        }
        return buf
    }
}
