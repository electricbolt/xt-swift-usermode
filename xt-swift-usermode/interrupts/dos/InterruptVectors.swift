// InterruptVectors.swift
// XT Copyright © 2025; Electric Bolt Limited.

import Foundation
import InterruptMacroPlugin
import XTSwiftCPU8088

public class InterruptVectors {

    @Interrupt(function: 0x25, description: "Set interrupt vector")
    func setInterruptVector(_ cpu: CPU, @AL _ interrupt: UInt8, @DS @DX _ address: SegOfs) {
        cpu.memory.setWord(SegOfs(UInt16(0), UInt16((4 * Int(interrupt)) + 2)), address.getSegment())
        cpu.memory.setWord(SegOfs(UInt16(0), UInt16(4 * Int(interrupt))), address.getOffset())
    }

    @Interrupt(function: 0x35, description: "Get interrupt vector")
    func getInterruptVector(_ cpu: CPU, @AL _ interrupt: UInt8) {
        cpu.reg.ES.setValue(cpu.memory.getWord(SegOfs(UInt16(0), UInt16((4 * Int(interrupt)) + 2))))
        cpu.reg.BX.setValue(cpu.memory.getWord(SegOfs(UInt16(0), UInt16(4 * Int(interrupt)))))
    }
}
