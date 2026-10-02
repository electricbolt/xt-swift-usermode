// BitArrayTests.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Testing
import Foundation

class BitArrayTests {

    @Test func testFirstFit() {
        let b = BitArray(count: 10)
        b.storage(fromString: "0000000000")
        #expect(b.storageToString() == "0000000000")
        var r = b.firstBlock(index: 0, count: 1)
        #expect(r!.index == 0 && r!.count == 1)
        r = b.firstBlock(index: 0, count: 10)
        #expect(r!.index == 0 && r!.count == 10)
        r = b.firstBlock(index: 0, count: 11)
        #expect(r == nil)

        b.storage(fromString:"1000000000")
        #expect(b.storageToString() == "1000000000")
        r = b.firstBlock(index: 0, count: 1)
        #expect(r!.index == 1 && r!.count == 1)

        b.storage(fromString:"1011001000")
        #expect(b.storageToString() == "1011001000")
        r = b.firstBlock(index: 0, count: 2)
        #expect(r!.index == 4 && r!.count == 2)
        r = b.firstBlock(index: 0, count: 3)
        #expect(r!.index == 7 && r!.count == 3)
        r = b.firstBlock(index: 0, count: 4)
        #expect(r == nil)

        r = b.firstBlock(index: 2, count: 1)
        #expect(r!.index == 4 && r!.count == 1)
        r = b.firstBlock(index: 2, count: 2)
        #expect(r!.index == 4 && r!.count == 2)
        r = b.firstBlock(index: 2, count: 3)
        #expect(r!.index == 7 && r!.count == 3)
        r = b.firstBlock(index: 2, count: 4)
        #expect(r == nil)
    }

    @Test func testAll() {
        let b = BitArray(count: 40)
        b.storage(fromString:"1111111111111111111111111111111111111111")
        var r = b.allBlocks(index: 0, minimumCount: 1, sortBy: .largest)
        #expect(r.isEmpty)

        b.storage(fromString:"0000000000000000000000000000000000000000")
        r = b.allBlocks(index: 0, minimumCount: 1, sortBy: .largest)
        #expect(r.count == 1)
        #expect(r[0].index == 0 && r[0].count == 40)

        b.storage(fromString:"1000000000000000000000000000000000000000")
        r = b.allBlocks(index: 0, minimumCount: 1, sortBy: .largest)
        #expect(r.count == 1)
        #expect(r[0].index == 1 && r[0].count == 39)

        b.storage(fromString:"1000000000000000000000000000000000000001")
        r = b.allBlocks(index: 0, minimumCount: 1, sortBy: .largest)
        #expect(r.count == 1)
        #expect(r[0].index == 1 && r[0].count == 38)

        b.storage(fromString:"1010010001001000110001000010000001000001")
        r = b.allBlocks(index: 0, minimumCount: 1, sortBy: .largest)
        #expect(r.count == 9)
        #expect(r[0].index == 27 && r[0].count == 6)
        #expect(r[1].index == 34 && r[1].count == 5)
        #expect(r[2].index == 22 && r[2].count == 4)
        #expect(r[3].index == 6 && r[3].count == 3)
        #expect(r[4].index == 13 && r[4].count == 3)
        #expect(r[5].index == 18 && r[5].count == 3)
        #expect(r[6].index == 3 && r[6].count == 2)
        #expect(r[7].index == 10 && r[7].count == 2)
        #expect(r[8].index == 1 && r[8].count == 1)

        b.storage(fromString:"1010010001001000110001000010000001000001")
        r = b.allBlocks(index: 0, minimumCount: 1, sortBy: .smallest)
        #expect(r.count == 9)
        #expect(r[0].index == 1 && r[0].count == 1)
        #expect(r[1].index == 3 && r[1].count == 2)
        #expect(r[2].index == 10 && r[2].count == 2)
        #expect(r[3].index == 6 && r[3].count == 3)
        #expect(r[4].index == 13 && r[4].count == 3)
        #expect(r[5].index == 18 && r[5].count == 3)
        #expect(r[6].index == 22 && r[6].count == 4)
        #expect(r[7].index == 34 && r[7].count == 5)
        #expect(r[8].index == 27 && r[8].count == 6)

        b.storage(fromString:"1010010001001000110001000010000001000001")
        r = b.allBlocks(index: 0, minimumCount: 4, sortBy: .smallest)
        #expect(r.count == 3)
        #expect(r[0].index == 22 && r[0].count == 4)
        #expect(r[1].index == 34 && r[1].count == 5)
        #expect(r[2].index == 27 && r[2].count == 6)
    }

    @Test func testCount() {
        let b = BitArray(count: 40)
        b.storage(fromString:"1111111111111111111111111111111111111111")
        var r = b.firstBlock(index: 0, count: 0)
        #expect(r == nil)

        b.storage(fromString:"0000000000000000000000000000000000000000")
        r = b.firstBlock(index: 0, count: 0)
        #expect(r!.index == 0 && r!.count == 40)

        b.storage(fromString:"1111111100000000000000000000000000000000")
        r = b.firstBlock(index: 0, count: 0)
        #expect(r!.index == 8 && r!.count == 32)

        b.storage(fromString:"1111111101000000000000000000000000000000")
        r = b.firstBlock(index: 0, count: 0)
        #expect(r!.index == 8 && r!.count == 1)

        b.storage(fromString:"1111111100000100000000000000000000000000")
        r = b.firstBlock(index: 0, count: 0)
        #expect(r!.index == 8 && r!.count == 5)

        r = b.firstBlock(index: 39, count: 0)
        #expect(r!.index == 39 && r!.count == 1)

        b.storage(fromString:"1111111100000100000000000000000000000001")
        r = b.firstBlock(index: 39, count: 0)
        #expect(r == nil)
    }

    @Test func testBestFit() {
        let b = BitArray(count: 40)
        b.storage(fromString:"0000000000000000000000000000000000000000")
        var r = b.nearestMatchingBlock(index: 0, count: 1)
        #expect(r!.index == 0 && r!.count == 1)
        r = b.nearestMatchingBlock(index: 0, count: 40)
        #expect(r!.index == 0 && r!.count == 40)
        r = b.nearestMatchingBlock(index: 0, count: 41)
        #expect(r == nil)

        b.storage(fromString:"0000000000000000000000000000000000000000")
        b.storage(fromString:"1100001000010000000100000000010010000010")
        r = b.nearestMatchingBlock(index: 0, count: 1)
        #expect(r!.index == 39 && r!.count == 1)
        r = b.nearestMatchingBlock(index: 0, count: 2)
        #expect(r!.index == 30 && r!.count == 2)
        r = b.nearestMatchingBlock(index: 0, count: 3)
        #expect(r!.index == 2 && r!.count == 3)
        r = b.nearestMatchingBlock(index: 0, count: 4)
        #expect(r!.index == 2 && r!.count == 4)
        r = b.nearestMatchingBlock(index: 0, count: 5)
        #expect(r!.index == 33 && r!.count == 5)
        r = b.nearestMatchingBlock(index: 0, count: 6)
        #expect(r!.index == 12 && r!.count == 6)
        r = b.nearestMatchingBlock(index: 0, count: 7)
        #expect(r!.index == 12 && r!.count == 7)
        r = b.nearestMatchingBlock(index: 0, count: 8)
        #expect(r!.index == 20 && r!.count == 8)
        r = b.nearestMatchingBlock(index: 0, count: 9)
        #expect(r!.index == 20 && r!.count == 9)
        r = b.nearestMatchingBlock(index: 0, count: 10)
        #expect(r == nil)
        r = b.nearestMatchingBlock(index: 5, count: 2)
        #expect(r!.index == 30 && r!.count == 2)
        r = b.nearestMatchingBlock(index: 5, count: 3)
        #expect(r!.index == 7 && r!.count == 3)
    }

    @Test func testLastFit() {
        let b = BitArray(count: 10)
        b.storage(fromString:"0000000000")
        var r = b.lastBlock(index: 0, count: 1)
        #expect(r!.index == 9 && r!.count == 1)
        r = b.lastBlock(index: 0, count: 8)
        #expect(r!.index == 2 && r!.count == 8)
        r = b.lastBlock(index: 0, count: 11)
        #expect(r == nil)

        b.storage(fromString:"0000000001")
        r = b.lastBlock(index: 1, count: 1)
        #expect(r!.index == 8 && r!.count == 1)

        b.storage(fromString:"0001001110")
        r = b.lastBlock(index: 0, count: 1)
        #expect(r!.index == 9 && r!.count == 1)

        b.storage(fromString:"0001001101")
        r = b.lastBlock(index: 0, count: 1)
        #expect(r!.index == 8 && r!.count == 1)
        r = b.lastBlock(index: 1, count: 1)
        #expect(r!.index == 8 && r!.count == 1)
        r = b.lastBlock(index: 2, count: 1)
        #expect(r!.index == 5 && r!.count == 1)

        b.storage(fromString:"0001001101")
        r = b.lastBlock(index: 0, count: 2)
        #expect(r!.index == 4 && r!.count == 2)
        r = b.lastBlock(index: 0, count: 3)
        #expect(r!.index == 0 && r!.count == 3)
        r = b.lastBlock(index: 0, count: 4)
        #expect(r == nil)
        r = b.lastBlock(index: 9, count: 1)
        #expect(r!.index == 0 && r!.count == 1)
        r = b.lastBlock(index: 5, count: 2)
        #expect(r!.index == 1 && r!.count == 2)
        r = b.lastBlock(index: 4, count: 2)
        #expect(r!.index == 4 && r!.count == 2)
    }
}
