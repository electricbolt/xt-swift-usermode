// MemoryAllocation.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation
import InterruptMacroPlugin
import XTSwiftCPU8088

public class MemoryAllocation {

    @Interrupt(function: 0x48, description: "Allocate memory block")
    func allocateMemoryBlock(_ cpu: CPU, _ trace: Trace, _ context: ExecutionContext, @BX _ paragraphs: UInt16) {
        do {
            let mcb = try context.memoryManager.alloc(algorithm: .firstFit, sizeInBytes: Int(paragraphs) * 16)!
            cpu.reg.flags.setCarry(false)
            cpu.reg.AX.setValue(mcb.segment &+ 1)
        } catch MemoryAllocError.invalidBlock {
            cpu.reg.flags.setCarry(true)
            cpu.reg.AX.setValue(ErrorCode.memoryBlockAddressInvalid.rawValue)
        } catch MemoryAllocError.insufficentMemory(let size) {
            cpu.reg.flags.setCarry(true)
            cpu.reg.AX.setValue(ErrorCode.insufficientMemory.rawValue)
            cpu.reg.BX.setValue(UInt16(ParagraphAlloc.toParagraphs(size)))
        } catch {
            print(error)
            exit(255)
        }
    }

    @Interrupt(function: 0x49, description: "Free memory block")
    func freeMemoryBlock(_ cpu: CPU, _ trace: Trace, _ context: ExecutionContext, @ES _ segment: UInt16) {
        let mcb = MCB(cpu.memory, segment)
        do {
            try context.memoryManager.free(mcb: mcb)
        } catch MemoryAllocError.invalidBlock {
            cpu.reg.flags.setCarry(true)
            cpu.reg.AX.setValue(ErrorCode.memoryBlockAddressInvalid.rawValue)
        } catch {
            print(error)
            exit(255)
        }
        cpu.reg.flags.setCarry(false)
    }

    @Interrupt(function: 0x4A, description: "Resize memory block")
    func resizeMemoryBlock(_ cpu: CPU, _ trace: Trace, _ context: ExecutionContext, @BX _ paragraphs: UInt16, @ES _ segment: UInt16) {
        do {
            let mcb = MCB(cpu.memory, segment &- 1)
            try context.memoryManager.resize(mcb: mcb, newSizeInBytes: Int(paragraphs) * 16)
            cpu.reg.flags.setCarry(false)
        } catch MemoryAllocError.invalidBlock {
            cpu.reg.flags.setCarry(true)
            cpu.reg.AX.setValue(ErrorCode.memoryBlockAddressInvalid.rawValue)
        } catch MemoryAllocError.insufficentMemory(let size) {
            cpu.reg.flags.setCarry(true)
            cpu.reg.AX.setValue(ErrorCode.insufficientMemory.rawValue)
            cpu.reg.BX.setValue(UInt16(ParagraphAlloc.toParagraphs(size)))
        } catch {
            print(error)
            exit(255)
        }
    }
}
