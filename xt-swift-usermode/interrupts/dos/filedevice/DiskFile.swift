// DiskFile.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

public class DiskFile: BaseFile {

    public override func open() -> Bool {
        fileURL = URL(fileURLWithPath: filename)
        switch accessMode {
            case .readOnly:
                randomAccessFile = FileHandle(forReadingAtPath: filename)
            case .writeOnly:
                randomAccessFile = FileHandle(forWritingAtPath: filename)
            case .readWrite:
                randomAccessFile = FileHandle(forUpdatingAtPath: filename)
        }
        return randomAccessFile != nil
    }

    public override func create() -> Bool {
        fileURL = URL(fileURLWithPath: filename)
        FileManager.default.createFile(atPath: filename, contents: nil)
        randomAccessFile = FileHandle(forUpdatingAtPath: filename)
        do {
            try randomAccessFile?.truncate(atOffset: 0)
            return true
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    /// Closes the file.
    ///
    /// - Returns: true if the file should be removed from the file handle map (user file), or false if it's a standard handle and should remain open.

    public override func close() -> Bool {
        try? randomAccessFile?.close()
        return true
    }

    public override func read(_ size: Int) -> [UInt8]? {
        guard let handle = randomAccessFile else { return nil }
        do {
            let data = try handle.read(upToCount: size)
            if data == nil || data!.isEmpty {
                return nil
            }
            return Array(data!)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    public override func write(_ buf: [UInt8]) {
        guard let handle = randomAccessFile else { return }
        do {
            try handle.write(contentsOf: Data(buf))
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    public override func seek(_ pos: Int32) {
        guard let handle = randomAccessFile else { return }
        do {
            try handle.seek(toOffset: UInt64(pos))
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    public override func size() -> Int32 {
        guard let handle = randomAccessFile else { return 0 }
        do {
            let current = try handle.offset()
            let end = try handle.seekToEnd()
            try handle.seek(toOffset: current)
            return Int32(end)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    public override func currentPos() -> Int32 {
        guard let handle = randomAccessFile else { return 0 }
        do {
            return Int32(try handle.offset())
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    public override func getDateTime() -> FileDateTime? {
        guard let fileURL = fileURL else { return nil }
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            guard let modDate = attrs[.modificationDate] as? Date else {
                return nil
            }
            return FileDateTime(modDate)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    public override func delete() -> Bool {
        guard let fileURL = fileURL else { return false }
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Internal

    private var fileURL: URL?
    private var randomAccessFile: FileHandle?
}
