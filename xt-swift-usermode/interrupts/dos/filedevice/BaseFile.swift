// BaseFile.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

public class BaseFile {

    public init(_ filename: String, _ accessMode: AccessMode, _ sharingMode: SharingMode, _ inheritenceFlag: Bool) {
        self.filename = filename
        self.accessMode = accessMode
        self.sharingMode = sharingMode
        self.inheritenceFlag = inheritenceFlag
    }

    public func setFileHandle(_ fileHandle: UInt16) {
        self.fileHandle = fileHandle
    }

    public func getFileHandle() -> UInt16 {
        return fileHandle
    }

    public func create() -> Bool {
        return false
    }

    public func open() -> Bool {
        return false
    }

    /// Closes the file.
    /// 
    /// - Returns: true if the file should be removed from the file handle map (user file), or false if
    ///   it's a standard handle and should remain open.
    
    public func close() -> Bool {
        return false
    }

    public func getDeviceInformationWord() -> UInt16 {
        return 0
    }

    public func read(_ size: Int) -> [UInt8]? {
        return nil
    }

    public func write(_ buf: [UInt8]) {
    }

    public func size() -> Int32 {
        return 0
    }

    public func seek(_ pos: Int32) {
    }

    public func currentPos() -> Int32 {
        return 0
    }

    public func getDateTime() -> FileDateTime? {
        return nil
    }

    public func delete() -> Bool {
        return false
    }

    // MARK: - Internal

    internal let filename: String
    internal let accessMode: AccessMode
    internal let sharingMode: SharingMode
    internal let inheritenceFlag: Bool
    internal var fileHandle: UInt16 = 0
}
