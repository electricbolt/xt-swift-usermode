// TimeDate.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation
import InterruptMacroPlugin
import XTSwiftCPU8088

public class DOSTimeDate {
    
    @Interrupt(function: 0x2A, description: "Get system date")
    func getSystemDate(_ cpu: CPU) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: Date())
        cpu.reg.CX.setValue(UInt16(components.year!)) // 1980-2099.
        cpu.reg.DH.setValue(UInt8(components.month! - 1))
        cpu.reg.DL.setValue(UInt8(components.day!))
        cpu.reg.AL.setValue(UInt8(components.weekday! - 1)) // 00h=Sunday.
    }

    @Interrupt(function: 0x2C, description: "Get system time")
    func getSystemTime(_ cpu: CPU) {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: now)
        let milliseconds = Int(now.timeIntervalSince1970 * 1000) % 1000
        cpu.reg.CH.setValue(UInt8(components.hour!))
        cpu.reg.CL.setValue(UInt8(components.minute!))
        cpu.reg.DH.setValue(UInt8(components.second!))
        cpu.reg.DL.setValue(UInt8(truncatingIfNeeded: milliseconds * 10))
    }
}
