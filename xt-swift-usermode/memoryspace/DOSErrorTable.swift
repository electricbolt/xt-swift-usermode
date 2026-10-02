// DOSErrorTable.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088

/// Error messages for functions and command line parsing. These messages would normally be resident in COMMAND.COM. Accessed by MS-DOS
/// programs (such as Microsoft LINK.EXE) through "Get or set error table address" INT 2F function 12 subfunction 2E.

public class DOSErrorTable: MemorySpace {

    public init(_ memory: Memory, _ paragraph: ParagraphAlloc) {
        super.init(memory, paragraph, DOSErrorTable.allocationSize)
        self.tableAddress = SegOfs(segment, 0)
        self.messageAddress = SegOfs(segment, UInt16(DOSErrorTable.tableSize))
        self.functionErrors = writeErrorsToMemory(DOSErrorTable.functionErrors)
        self.parsingErrors = writeErrorsToMemory(DOSErrorTable.parsingErrors)

        // Uncomment to dump out the memory used to hold the errors in a structure DOS is expecting.
        // memory.dump(SegOfs(segment, 0), DOSErrorTable.allocationSize)
    }

    public func functionErrorsTable() -> SegOfs {
        return functionErrors
    }

    public func parsingErrorsTable() -> SegOfs {
        return parsingErrors
    }

    // MARK: - Internal

    private static let functionErrors = [
        "Invalid function", // 1
        "File not found", // 2
        "Path not found", // 3
        "Too many open files", // 4
        "Access denied ", // 5
        "Invalid handle", // 6
        "Memory control blocks destroyed", // 7
        "Insufficient memory", // 8
        "Invalid memory block address", // 9
        "Invalid Environment", // 10
        "Invalid format", // 11
        "Invalid function parameter", // 12
        "Invalid data", // 13
        "", // 14
        "Invalid drive specification", // 15
        "Attempt to remove current directory", // 16
        "Not same device", // 17
        "No more files", // 18
        "Write protect error", // 19
        "Invalid unit", // 20
        "Not ready", // 21
        "Invalid device request", // 22
        "Data error", // 23
        "Invalid device request parameters", // 24
        "Seek error", // 25
        "Invalid media type", // 26
        "Sector not found", // 27
        "Printer out of paper error", // 28
        "Write fault error", // 29
        "Read fault error", // 30
        "General failure", // 31
        "Sharing violation", // 32
        "Lock violation", // 33
        "Invalid disk change", // 34
        "FCB unavailable", // 35
        "System resource exhausted", // 36
        "Code page mismatch", // 37
        "Out of input", // 38
        "Insufficient disk space", // 39
        "", // 40
        "", // 41
        "", // 42
        "", // 43
        "", // 44
        "", // 45
        "", // 46
        "", // 47
        "", // 48
        "", // 49
        "NET809: Network request not supported", // 50
        "NET801: Remote computer not listening", // 51
        "NET802: Duplicate name on network", // 52
        "NET803: Network path not found", // 53
        "NET804: Network busy", // 54
        "NET805: Network device no longer exists", // 55
        "NET806: NETBIOS command limit exceeded", // 56
        "NET807: System error; NETBIOS error", // 57
        "NET808: Incorrect response from network", // 58
        "NET810: Unexpected network error", // 59
        "NET811: Incompatible remote adapter", // 60
        "NET812: Print queue full", // 61
        "NET813: Not enough space for print file", // 62
        "NET814: Print file was cancelled", // 63
        "NET815: Network name was deleted", // 64
        "Access denied", // 65
        "NET817: Network device type incorrect", // 66
        "NET818: Network name not found", // 67
        "NET819: Network name limit exceeded", // 68
        "NET820: NETBIOS session limit exceeded", // 69
        "NET821: Sharing temporarily paused", // 70
        "NET823: Network request not accepted", // 71
        "NET822: Print or disk redirection is paused", // 72
        "NET476: Netbeui not loaded", // 73
        "NET477: Unexpected adapter close", // 74
        "", // 75
        "", // 76
        "", // 77
        "", // 78
        "", // 79
        "File exists", // 80
        "", // 81
        "Cannot make directory entry", // 82
        "Fail on INT 24", // 83
        "Too many redirections", // 84
        "Duplicate redirection", // 85
        "Invalid password", // 86
        "Invalid parameter", // 87
        "Network data fault", // 88
        "Function not supported by network", // 89
        "Required system component not installed", // 90
    ]

    private static let parsingErrors = [
        "Too many parameters", // 1
        "Required parameter missing", // 2
        "Invalid switch", // 3
        "Invalid keyword", // 4
        "", // 5
        "Parameter value not in allowed range", // 6
        "Parameter value not allowed", // 7
        "Parameter value not allowed", // 8
        "Parameter format not correct", // 9
        "Invalid parameter", // 10
        "Invalid parameter combination" // 11
    ]

    private static let allocationSize = calculateAllocationSize()
    private static let tableSize = 8 + 4 * (DOSErrorTable.functionErrors.count + DOSErrorTable.parsingErrors.count)
    private var tableAddress: SegOfs!
    private var messageAddress: SegOfs!
    private var functionErrors: SegOfs!
    private var parsingErrors: SegOfs!
    
    private static func calculateAllocationSize() -> Int {
        let functionErrorsSize = errorMessageSize(functionErrors)
        let parsingErrorsSize = errorMessageSize(parsingErrors)
        let errorTableSize = 8 + 4 * (functionErrors.count + parsingErrors.count)
        return ParagraphAlloc.toParagraphs(errorTableSize + functionErrorsSize + parsingErrorsSize) * 16
    }

    private static func errorMessageSize(_ errors: [String]) -> Int {
        var size = 0
        for i in 0..<errors.count {
            size += errors[i].count + 1
        }
        return size
    }

    private func writeErrorsToMemory(_ errors: [String]) -> SegOfs {
        let startTableAddress = tableAddress!
        writeTableByte(0xFF)
        writeTableByte(0x04)
        writeTableByte(0x00)
        writeTableByte(UInt8(errors.count))
        for i in 0..<errors.count {
            writeTableWord(UInt16(i + 1))
            writeTableWord(messageAddress.getOffset())
            writeMessageString(errors[i])
        }
        return startTableAddress
    }

    private func writeMessageString(_ str: String) {
        writeMessageByte(UInt8(str.count))
        for char in str {
            writeMessageByte(char.asciiValue!)
        }
    }

    private func writeMessageByte(_ value: UInt8) {
        memory.setByte(messageAddress, value)
        messageAddress.increment()
    }

    private func writeTableByte(_ value: UInt8) {
        memory.setByte(tableAddress, value)
        tableAddress.increment()
    }

    private func writeTableWord(_ value: UInt16) {
        memory.setWord(tableAddress, value)
        tableAddress.addOffset(2)
    }
}
