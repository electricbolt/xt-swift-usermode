// DirectoryTranslation.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

public class DirectoryTranslation {

    public let workingDirectory: String

    public init(_ workingDirectory: String) {
        self.workingDirectory = workingDirectory;
    }

    /// Converts an emulated MS-DOS program path to a host path rooted from the working directory. e.g.
    ///
    /// Working directory = /Users/matthew/Documents
    /// Emulated path = C:\Dev\TASM.EXE
    /// Result = /Users/matthew/Documents/Dev/TASM.EXE

    public func emulatedPathToHostPath(_ path: String) -> String {
        var path = path
        path = path.removePrefix("C:")
        path = path.replacingOccurrences(of: "\\", with: "/")
        path = path.removeSuffix("/")
        path = DirectoryTranslation.normalize(path)
        path = workingDirectory + path
        return path
    }

    /// Resolves `.` and `..` components in a `/`-separated path, without ever allowing the result to traverse above the root (any `..` beyond the
    /// root is discarded, matching how MS-DOS clamps `cd ..` at the root of a drive).

    internal static func normalize(_ path: String) -> String {
        var components: [Substring] = []
        for component in path.split(separator: "/", omittingEmptySubsequences: true) {
            if component == "." {
                continue
            } else if component == ".." {
                if !components.isEmpty {
                    components.removeLast()
                }
            } else {
                components.append(component)
            }
        }
        if components.isEmpty {
            return ""
        }
        return "/" + components.joined(separator: "/")
    }

    /// Converts a host path to an emulated MS-DOS program path. e.g.
    ///
    /// Working directory = /Users/matthew/Documents
    /// Host path = /Users/matthew/Documents/Dev/TASM.EXE
    /// Result = C:\Dev\TASM.EXE

    public func hostPathToEmulatedPath(_ path: String) -> String {
        var path = path
        path = path.removePrefix(workingDirectory)
        path = path.replacingOccurrences(of: "/", with: "\\")
        if !path.hasPrefix("\\") {
            path = "\\" + path
        }
        path = "C:" + path;
        return path
    }
}
