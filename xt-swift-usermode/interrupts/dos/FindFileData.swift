// FindFileData.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

public struct FindFileData {
    
    public let internalId: UInt16
    public let files: [String]
    public let fileIndex: UInt16
    public let diskTransferArea: DiskTransferArea

    public init(internalId: UInt16, files: [String], fileIndex: UInt16, diskTransferArea: DiskTransferArea) {
        self.internalId = internalId
        self.files = files
        self.fileIndex = fileIndex
        self.diskTransferArea = diskTransferArea
    }
}
