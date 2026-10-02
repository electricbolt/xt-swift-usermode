// StandardError.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

public var stderr = StandardError()

public struct StandardError: TextOutputStream {

    public func write(_ string: String) {
        Self.handle.write(Data(string.utf8))
    }

    // MARK: - Internal

    private static let handle = FileHandle.standardError
}
