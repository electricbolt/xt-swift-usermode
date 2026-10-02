// BIOSEquipmentList.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Foundation
import InterruptMacroPlugin
import XTSwiftCPU8088

public class BIOSEquipmentList {

    @Interrupt(interrupt: 0x11, description: "Get equipment list")
    func getEquipmentList(_ cpu: CPU) {
        // Bit 0 = floppy disk(s) installed. (zero = 0b)
        // Bit 1 = 80x87 coprocessor installed. (no = 0b)
        // Bit 2,3 = Unused. (00b)
        // Bit 4,5 = Initial video mode. (80x25 monochrome = 11b)
        // Bit 6,7 = Number of floppies installed less 1. (zero = 00b)
        // Bit 8 = DMA support installed. (no = 0b)
        // Bit 9-11 = Number of serial ports installed. (zero = 000b)
        // Bit 12 = Game port installed. (no = 0b)
        // Bit 13 = Internal modem installed. (no = 0b)
        // Bit 14,15 = Number of parallel ports installed. (zero = 00b)
        cpu.reg.AX.setValue(0b0000_0000_0011_0000)
    }

    @Interrupt(interrupt: 0x12, description: "Get memory size")
    func getMemorySize(_ cpu: CPU) {
        cpu.reg.AX.setValue(1024)
    }

    @Interrupt(interrupt: 0x15, function: 0xC1, description: "Return extended BIOS data area")
    func getExtendedBIOSDataArea(_ cpu: CPU) {
        // do nothing, invoked to check for PS/2 systems [MEM.EXE 4.01]
    }
}
