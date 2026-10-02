// TerminateProgram.swift
// XT Copyright © 2025; Electric Bolt Limited.

import Foundation
import InterruptMacroPlugin
import XTSwiftCPU8088

public class TerminateProgram {

    @Interrupt(interrupt: 0x20, description: "Terminate program")
    func terminate1(_ cpu: CPU) {
        exit(0)
    }

    @Interrupt(function: 0x00, description: "Terminate program")
    func terminate2(_ cpu: CPU) {
        exit(0)
    }

    @Interrupt(function: 0x4C, description: "Terminate program with exit code")
    func terminate3(_ cpu: CPU, @AL _ exitCode: UInt8) {
        exit(Int32(cpu.reg.AL.getValue()))
    }
}
