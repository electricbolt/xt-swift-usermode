// ParagraphAllocTests.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Testing
import Foundation

class ParagraphAllocTests {

    @Test func testToParagraphs() {
        #expect(ParagraphAlloc.toParagraphs(1) == 1)
        #expect(ParagraphAlloc.toParagraphs(2) == 1)
        #expect(ParagraphAlloc.toParagraphs(3) == 1)
        #expect(ParagraphAlloc.toParagraphs(14) == 1)
        #expect(ParagraphAlloc.toParagraphs(15) == 1)
        #expect(ParagraphAlloc.toParagraphs(16) == 1)
        #expect(ParagraphAlloc.toParagraphs(17) == 2)
        #expect(ParagraphAlloc.toParagraphs(18) == 2)
        #expect(ParagraphAlloc.toParagraphs(19) == 2)
        #expect(ParagraphAlloc.toParagraphs(30) == 2)
        #expect(ParagraphAlloc.toParagraphs(31) == 2)
        #expect(ParagraphAlloc.toParagraphs(32) == 2)
        #expect(ParagraphAlloc.toParagraphs(33) == 3)
    }

    @Test func allocFirstAndResize() {
        let m = ParagraphAlloc()

        var seg1 = 0
        var seg2 = 0
        var seg3 = 0
        var seg4 = 0

        do {
            seg1 = try m.alloc(algorithm: .firstFit, sizeInBytes: 1020)
            #expect(seg1 == 0x0)
            seg2 = try m.alloc(algorithm: .firstFit, sizeInBytes: 250)
            #expect(seg2 == 0x40)
            seg3 = try m.alloc(algorithm: .firstFit, sizeInBytes: 510)
            #expect(seg3 == 0x50)
        } catch {
            #expect(Bool(false), "Should not have thrown \(error)")
        }

        do {
            _ = try m.alloc(algorithm: .firstFit, sizeInBytes: 1048000)
            #expect(Bool(false), "Should have thrown ParagraphAllocError.insufficentMemory")
        } catch ParagraphAllocError.insufficentMemory(let size) {
            #expect(size == 1046784)
        } catch {
            #expect(Bool(false), "Should not have thrown \(error)")
        }

        do {
            // Resize seg2 from 16 paragraphs down to 8 paragraphs.
            try m.resize(from: seg2, oldSizeInBytes: 250, newSizeInBytes: 120)
        } catch {
            #expect(Bool(false), "Should not have thrown \(error)")
        }

        do {
            // Allocate 9 paragraphs, will go after seg4 as free space from seg2 resize is only 8 paragraphs
            seg4 = try m.alloc(algorithm: .firstFit, sizeInBytes: 130) // 9 paragraphs
            #expect(seg4 == 0x70)
        } catch {
            #expect(Bool(false), "Should not have thrown \(error)")
        }

        do {
            // Resize seg2 from 8 paragraphs up to 17 paragraphs.
            try m.resize(from: seg2, oldSizeInBytes: 120, newSizeInBytes: 257)
            #expect(Bool(false), "Should not have resized")
        } catch ParagraphAllocError.insufficentMemory(let size) {
            #expect(size == 128)
        } catch {
            #expect(Bool(false), "Should not have thrown \(error)")
        }
    }

    @Test func allocBestAndFree() {
        let m = ParagraphAlloc()

        var seg1 = 0
        var seg2 = 0
        var seg3 = 0
        var seg4 = 0
        var seg5 = 0
        var seg6 = 0
        var seg7 = 0

        do {
            seg1 = try m.alloc(algorithm: .bestFit, sizeInBytes: 1020)
            #expect(seg1 == 0x0)
            seg2 = try m.alloc(algorithm: .bestFit, sizeInBytes: 128)
            #expect(seg2 == 0x40)
            seg3 = try m.alloc(algorithm: .bestFit, sizeInBytes: 32)
            #expect(seg3 == 0x48)
            seg4 = try m.alloc(algorithm: .bestFit, sizeInBytes: 32)
            #expect(seg4 == 0x4A)
            seg5 = try m.alloc(algorithm: .bestFit, sizeInBytes: 32)
            #expect(seg5 == 0x4C)
            seg6 = try m.alloc(algorithm: .bestFit, sizeInBytes: 32)
            #expect(seg6 == 0x4E)
            seg7 = try m.alloc(algorithm: .firstFit, sizeInBytes: 510)
            #expect(seg7 == 0x50)

            try m.free(from: seg2, sizeInBytes: 128)
            try m.free(from: seg4, sizeInBytes: 32)

            seg4 = try m.alloc(algorithm: .bestFit, sizeInBytes: 28)
            #expect(seg4 == 0x4A)
        } catch {
            #expect(Bool(false), "Should not have thrown \(error)")
        }
    }

    @Test func allocLast() {
        let m = ParagraphAlloc()

        var seg1 = 0
        var seg2 = 0

        do {
            seg1 = try m.alloc(algorithm: .lastFit, sizeInBytes: 1020)
            #expect(seg1 == 0xFFC0)
            seg2 = try m.alloc(algorithm: .lastFit, sizeInBytes: 250)
            #expect(seg2 == 0xFFB0)
        } catch {
            #expect(Bool(false), "Should not have thrown \(error)")
        }

        do {
            seg1 = try m.alloc(algorithm: .lastFit, sizeInBytes: 1048576)
            #expect(Bool(false), "Should have thrown ParagraphAllocError.insufficentMemory")
        } catch ParagraphAllocError.insufficentMemory(let size) {
            #expect(size == 1047296)
        } catch {
            #expect(Bool(false), "Should not have thrown \(error)")
        }
    }

}
