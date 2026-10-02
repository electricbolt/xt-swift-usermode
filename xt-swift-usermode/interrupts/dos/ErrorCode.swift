// ErrorCode.java
// XT Copyright © 2025-2026; Electric Bolt Limited.

/// Error codes from PC-Interrupts 2nd edition, Chapter 24, MS-DOS Kernel.

import Foundation
import InterruptMacroPlugin
import XTSwiftCPU8088

public enum ErrorCode: UInt16, CaseIterable {

    case noError = 0
    case functionNumberInvalid = 1
    case fileNotFound = 2
    case pathNotFound = 3
    case tooManyOpenFiles = 4
    case accessDenied = 5
    case invalidHandle = 6
    case memoryControlBlockDestroyed = 7
    case insufficientMemory = 8
    case memoryBlockAddressInvalid = 9
    case environmentInvalid = 10
    case formatInvalid = 11
    case accessCodeInvalid = 12
    case dataInvalid = 13
    case reserved1 = 14
    case invalidDrive = 15
    case attemptedToRemoveCurrentDirectory = 16
    case notSameDevice = 17
    case noMoreFiles = 18
    case diskWriteProtected = 19
    case unknownUnit = 20
    case driveNotReady = 21
    case unknownCommand = 22
    case dataErrorCRC = 23
    case badRequestStructureLength = 24
    case seekError = 25
    case unknownMediaType = 26
    case sectorNotFound = 27
    case printerOutOfPaper = 28
    case writeFault = 29
    case readFault = 30
    case generalFailure = 31
    case sharingViolation = 32
    case lockViolation = 33
    case diskChangeInvalid = 34
    case FCBUnavailable = 35
    case sharingBufferOverflow = 36
    case codePageMismatch = 37
    case cannotCompleteFileOperation = 38
    case insufficientDiskSpace = 39
    case fileExists = 80
    case cannotMakeDirectory = 82
    case failOnInt24 = 83
}

public class ErrorTable {

    @Interrupt(interrupt: 0x2F, function: 0x12, subfunction: 0x2E, description: "Get or set error table address")
    func getOrSetErrorTable(_ cpu: CPU, _ trace: Trace, _ context: ExecutionContext, @DL _ subfunction: UInt8) {
        switch subfunction {
            case 0x00:
                let table = context.err.functionErrorsTable()
                cpu.reg.ES.setValue(table.getSegment())
                cpu.reg.DI.setValue(table.getOffset())
            case 0x02:
                let table = context.err.parsingErrorsTable()
                cpu.reg.ES.setValue(table.getSegment())
                cpu.reg.DI.setValue(table.getOffset())
            case 0x04:
                // Critical/SHARE errors table
                cpu.reg.ES.setValue(0x0000)
                cpu.reg.DI.setValue(0x0000)
            case 0x06:
                // Get unknown error messages - not documented in PC-Interrupts 2nd edition book. [MEM.EXE 4.01]
                cpu.reg.ES.setValue(0x0000)
                cpu.reg.DI.setValue(0x0000)
            case 0x08:
                // Error retrieval function. [MEM.EXE 4.01]
                cpu.reg.ES.setValue(0x0000)
                cpu.reg.DI.setValue(0x0000)
            default:
                trace.log(String(format: "Unhandled interrupt 2F function 122E subfunction %02X", subfunction));
                trace.log(cpu.reg.description);
                print(String(format: "Unhandled interrupt 2F function 122E subfunction %02X", subfunction));
                print(cpu.reg.description);
                exit(255)
        }
    }
}

