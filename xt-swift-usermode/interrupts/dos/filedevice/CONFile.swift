// CONFile.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

private extension UInt8 {
    static let carriageReturn: UInt8 = 0x0D
    static let newline: UInt8 = 0x0A
    static let delete: UInt8 = 0x7F
    static let escape: UInt8 = 0x1B
    static let tab: UInt8 = 0x09
}

public class CONFile: BaseFile {

    public init(accessMode: AccessMode, sharingMode: SharingMode, inheritenceFlag: Bool, stdout: Bool) {
        self.stdout = stdout
        super.init("CON", accessMode, sharingMode, inheritenceFlag);
    }

    public override func open() -> Bool {
        return true
    }

    public override func close() -> Bool {
        return false
    }

    public override func getDeviceInformationWord() -> UInt16 {
        return 0x80D3;
    }

    /// Reads maximum of `size` characters from the terminal, or until the return key is detected.
    /// 
    /// Space permitting, two, one or none of `\r\n` is prepended to the result.

    public override func read(_ size: Int) -> [UInt8]? {
        // Check if any IntegrationTest requires exiting on standard input (otherwise would block).
        if let exitOnStdIn = ProcessInfo.processInfo.environment["XT_EXIT_ON_STDIN"] {
            if let exitCode = Int32(exitOnStdIn) {
                exit(exitCode)
            }
        }

        var buf = [UInt8]()
loop:   while buf.count < size {
            if var c = readKey() {
                switch (c) {
                case .delete:
                    if !buf.isEmpty {
                        buf = Array(buf.dropLast(1))
                        Foundation::write(STDOUT_FILENO, "\u{8} \u{8}", 3)
                    }
                case .carriageReturn, .newline:
                    buf.append(Character("\r").asciiValue!)
                    buf.append(Character("\n").asciiValue!)
                    Foundation::write(STDOUT_FILENO, "\n", 1)
                    break loop
                default:
                    buf.append(c)
                    Foundation::write(STDOUT_FILENO, &c, 1)
                }
            }
        }
        if buf.count > size {
            return Array(buf[0..<size])
        } else {
            return buf
        }
    }

    public override func write(_ buf: [UInt8]) {
        let s = String(fromCP437: buf) // Original IBM PC/XT character set.
        Foundation::write(stdout ? STDOUT_FILENO : STDERR_FILENO, s, s.utf8.count)
    }

    // MARK: - Internal

    private var stdout: Bool

    /// Reads a key from the terminal using raw input mode.

    private func readKey() -> UInt8? {
        var original = termios()
        tcgetattr(STDIN_FILENO, &original)

        var raw = original
        raw.c_lflag &= ~(UInt(ECHO | ICANON)) // no echo, no line buffering
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
        defer { tcsetattr(STDIN_FILENO, TCSAFLUSH, &original) }

        var byte: UInt8 = 0
        return Foundation::read(STDIN_FILENO, &byte, 1) == 1 ? byte : nil
    }
}
