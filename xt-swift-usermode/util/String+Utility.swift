// String+Utility.swift
// CoreKit, XT Copyright© 2019-2026; Electric Bolt Limited.

import Foundation

/// Utility extensions to Swift's String class.

public extension String {
    
    /// Returns a string object containing the `length` lefthand most characters of the receiver.
    ///
    /// If the length is out of bounds, then the length is automatically repaired to be in bounds, with the returned string appropriately adjusted. Example:
    /// "my dog has fleas".left(6) == "my dog"

    func left(_ length: Int) -> String {
        return self[..<length]
    }

    /// Returns a string object containing the `length` righthand most characters of the receiver.
    ///
    /// If the length is out of bounds, then the length is automatically repaired to be in bounds, with the returned string appropriately adjusted. Example:
    /// "my dog has fleas".left(5) == "fleas"

    func right(_ length: Int) -> String {
        return self[(self.count-length)...]
    }

    /// If the receiver has the prefix specified, then returns the receiver with the prefix removed, otherwise returns the receiver.

    func removePrefix(_ string: String) -> String {
        if string != "" && self.hasPrefix(string) {
            let startIndex = self.index(self.startIndex, offsetBy: string.count)
            return String(self[startIndex...])
        } else {
            return self
        }
    }

    /// If the receiver has the suffix specified, then returns the receiver with the suffix removed, otherwise returns the receiver.

    func removeSuffix(_ string: String) -> String {
        if self == string {
            return ""
        } else if string != "" && self.hasSuffix(string) {
            let endIndex = self.index(self.endIndex, offsetBy: -string.count)
            return String(self[..<endIndex])
        } else {
            return self
        }
    }
}
