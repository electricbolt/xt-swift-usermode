// BIOSTimeDate.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation
import InterruptMacroPlugin
import XTSwiftCPU8088

public class BIOSTimeDate {

    @Interrupt(interrupt: 0x1A, function: 0x00, description: "Get system time clock ticks")
    func getSystemTimeClockTicks(_ cpu: CPU, _ trace: Trace, _ context: ExecutionContext) {
        let now = context.bda.timeInClockTicks()
        cpu.reg.CX.setValue(UInt16((now >> 16) & 0xFFFF))
        cpu.reg.DX.setValue(UInt16(now & 0xFFFF))
        cpu.reg.AL.setValue(UInt8(0)) // past midnight.
    }
}
