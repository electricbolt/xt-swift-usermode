// DiskTransferArea.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088

/// Disk Transfer Area. Only fields `fileAttribute ... fileName` are documented, all others undocumented.

public class DiskTransferArea: MemorySpace {

    public init(_ memory: Memory, _ segment: UInt16, _ offset: UInt16) {
        assert(MemoryLayout<_DTA>.offset(of: \.internalId) == 0x11)
        assert(MemoryLayout<_DTA>.offset(of: \.fileName) == 0x1E)
        super.init(memory, segment, offset, MemoryLayout<_DTA>.size)
    }

    public func getInternalId() -> UInt16 {
        return readWord(ofs.internalId)
    }

    public func setInternalId(_ internalId: UInt16) {
        setWord(ofs.internalId, internalId)
    }

    public func writeFileAttribute(_ fileAttribute: UInt8) {
        setWord(ofs.fileAttribute, UInt16(fileAttribute))
    }

    public func writeFileTime(_ fileTime: UInt16) {
        setWord(ofs.fileTime, fileTime)
    }

    public func writeFileDate(_ fileDate: UInt16) {
        setWord(ofs.fileDate, fileDate)
    }

    public func writeFileSize(_ fileSize: Int) {
        setDoubleWord(ofs.fileSize, UInt32(bitPattern: Int32(fileSize)))
    }

    public func writeFilename(_ filename: String) {
        for i in 0..<filename.count {
            let c = filename[filename.index(filename.startIndex, offsetBy: i)]
            setByte(ofs.fileName + i, c.asciiValue ?? 0)
        }
        setByte(ofs.fileName + filename.count, 0x00)
    }

    private struct Ofs {
        let internalId = MemoryLayout<_DTA>.offset(of: \.internalId)!
        let fileAttribute = MemoryLayout<_DTA>.offset(of: \.fileAttribute)!
        let fileTime = MemoryLayout<_DTA>.offset(of: \.fileTime)!
        let fileDate = MemoryLayout<_DTA>.offset(of: \.fileDate)!
        let fileSize = MemoryLayout<_DTA>.offset(of: \.fileSize)!
        let fileName = MemoryLayout<_DTA>.offset(of: \.fileName)!
    }
    private let ofs = Ofs()
}
