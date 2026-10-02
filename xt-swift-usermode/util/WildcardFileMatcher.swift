// WildcardFileMatcher.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

public class WildcardFileMatcher {

    public init(_ wildcard: String) {
        var wildcard = wildcard
        wildcard = wildcard.replacingOccurrences(of: ".", with: "\\.")
        wildcard = wildcard.replacingOccurrences(of: "?", with: ".")
        wildcard = wildcard.replacingOccurrences(of: "*", with: ".*?")
        pattern = try! NSRegularExpression(pattern: wildcard)
    }

    public func matches(_ filename: String) -> Bool {
        let range = NSRange(filename.startIndex..., in: filename)
        guard let match = pattern.firstMatch(in: filename, range: range) else {
            return false
        }
        return match.range == range
    }

    // MARK: - Internal

    private let pattern: NSRegularExpression
}
