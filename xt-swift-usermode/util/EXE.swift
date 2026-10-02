// EXEHeader.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088

public class EXE {

    public init(_ buf: [UInt8]) {
        self.buf = buf
    }

    public func getLastPageSize() -> Int {
        return getWord(ofs.lastPageSize)
    }

    public func getPages() -> Int {
        return getWord(ofs.pages)
    }

    public func getRelocationEntries() -> Int {
        return getWord(ofs.relocationEntries)
    }

    public func getParagraphsInHeader() -> Int {
        return getWord(ofs.paragraphsInHeader)
    }

    public func getParagraphsForUninitializedData() -> Int {
        return getWord(ofs.paragraphsForUninitializedData)
    }

    public func getParagraphsToConstrainMemory() -> Int {
        return getWord(ofs.paragraphsToConstrainMemory)
    }

    public func getRelativeSS() -> Int {
        return getWord(ofs.relativeSS)
    }

    public func getSP() -> Int {
        return getWord(ofs.SP)
    }

    public func getCheckSum() -> Int {
        return getWord(ofs.checksum)
    }

    public func getIP() -> Int {
        return getWord(ofs.IP)
    }

    public func getRelativeCS() -> Int {
        return getWord(ofs.relativeCS)
    }

    public func getOffsetFirstRelocationItem() -> Int {
        return getWord(ofs.offsetFirstRelocationItem)
    }

    public func getOverlayNumber() -> Int {
        return getWord(ofs.overlayNumber)
    }

    public func relocationItem(_ i: Int) -> SegOfs {
        let ofs = getWord(getOffsetFirstRelocationItem() + (i * 4))
        let seg = getWord(getOffsetFirstRelocationItem() + (i * 4) + 2)
        return SegOfs(UInt16(seg), UInt16(ofs))
    }

    // MARK: - Internal

    private struct Ofs {
        let signature = MemoryLayout<_EXE>.offset(of: \.signature)!
        let lastPageSize = MemoryLayout<_EXE>.offset(of: \.lastPageSize)!
        let pages = MemoryLayout<_EXE>.offset(of: \.pages)!
        let relocationEntries = MemoryLayout<_EXE>.offset(of: \.relocationEntries)!
        let paragraphsInHeader = MemoryLayout<_EXE>.offset(of: \.paragraphsInHeader)!
        let paragraphsForUninitializedData = MemoryLayout<_EXE>.offset(of: \.paragraphsForUninitializedData)!
        let paragraphsToConstrainMemory = MemoryLayout<_EXE>.offset(of: \.paragraphsToConstrainMemory)!
        let relativeSS = MemoryLayout<_EXE>.offset(of: \.relativeSS)!
        let SP = MemoryLayout<_EXE>.offset(of: \.SP)!
        let checksum = MemoryLayout<_EXE>.offset(of: \.checksum)!
        let IP = MemoryLayout<_EXE>.offset(of: \.IP)!
        let relativeCS = MemoryLayout<_EXE>.offset(of: \.relativeCS)!
        let offsetFirstRelocationItem = MemoryLayout<_EXE>.offset(of: \.offsetFirstRelocationItem)!
        let overlayNumber = MemoryLayout<_EXE>.offset(of: \.overlayNumber)!
    }
    private let ofs = Ofs()

    private let buf: [UInt8]

    private func getWord(_ offset: Int) -> Int {
        return Int(buf[offset]) | (Int(buf[offset + 1]) << 8)
    }
}
