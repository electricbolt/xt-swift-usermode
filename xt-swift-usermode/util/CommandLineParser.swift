// CommandLineParser.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

public class CommandLineParser {

    public init(_ args: [String]) {
        self.args = args
        self.index = 0
    }

    public func hasNext() -> Bool {
        return index < args.count
    }

    public func peek() -> String? {
        if hasNext() {
            return args[index]
        } else {
            return nil
        }
    }

    public func next() -> String? {
        if hasNext() {
            let result = args[index]
            index += 1
            return result
        } else {
            return nil
        }
    }

    // MARK: - Internal

    private let args: [String]
    private var index: Int
}
