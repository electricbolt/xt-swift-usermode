// Memory+Utility.h
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088

public extension Memory {

    func map<T>(_ from: SegOfs) -> UnsafeMutablePointer<T> {
        let offset = from.toLinearAddress()
        let pointer = buf.baseAddress!.advanced(by: offset)
        let rawPointer = UnsafeMutableRawPointer(pointer)
        return rawPointer.assumingMemoryBound(to: T.self)
    }

    func fill(_ to: SegOfs, _ length: UInt16, _ fill: UInt8) {
        let to = to.copy()
        for _ in 0..<length {
            writeByte(to, fill)
            to.increment()
        }
    }

    func readBuf(_ from: SegOfs, _ length: UInt16) -> [UInt8] {
        let from = from.copy()
        let result = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: Int(length))
        for i in 0..<Int(length) {
            result[i] = readByte(from)
            from.increment()
        }
        return Array(result)
    }

    func writeBuf(_ to: SegOfs, _ buf: [UInt8]) {
        let to = to.copy()
        for i in 0..<buf.count {
            writeByte(to, buf[i])
            to.increment();
        }
    }

    func readStringZ(_ from: SegOfs, _ terminationChar: Character) -> String {
        var buf = ""
        while (true) {
            let c = Character(UnicodeScalar(readByte(from)))
            from.increment()
            if c == terminationChar {
                break
            }
            buf.append(c)
        }
        return buf
    }

    func dump(_ address: SegOfs, _ count: Int = 64) {
        let offset = address.getOffset() & 0xFFF0 // Align to 16 byte boundary.
        address.setOffset(offset)
        var ascii = ""
        for i in 0..<count {
            if i % 16 == 0 {
                // Start of line.
                print(String(format: "%04X:%04X: ", address.getSegment(), address.getOffset()), terminator: "", to: &stderr)
            }
            let b = getByte(address)
            print(String(format: "%02X ", b), terminator: "", to: &stderr)
            if b >= 32 {
                ascii += String(fromCP437: [b])
            } else {
                ascii += "☐"
            }
            if i % 16 == 15 {
                print(ascii, to: &stderr)
                ascii = ""
            }
            address.increment()
            if address.toLinearAddress() == 0 {
                return
            }
        }
    }
}
