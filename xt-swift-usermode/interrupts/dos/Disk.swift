// Disk.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Foundation
import InterruptMacroPlugin
import XTSwiftCPU8088

public class Disk {

    @Interrupt(function: 0x19, description: "Get current default drive")
    func getCurrentDefaultDrive(_ cpu: CPU) {
        cpu.reg.AL.setValue(0x02) // C:
    }
}
