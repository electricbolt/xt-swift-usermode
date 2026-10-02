// ConsoleIO.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation
import InterruptMacroPlugin
import XTSwiftCPU8088

public class ConsoleIO {

    @Interrupt(function: 0x02, description: "Write character to standard output")
    func writeChar(_ cpu: CPU, @DL _ c: Character) {
        var c = c.asciiValue!
        Foundation::write(STDOUT_FILENO, &c, 1)
    }

    @Interrupt(function: 0x09, description: "Write string to standard output")
    private func writeString(_ cpu: CPU, @ASCIZ(terminator: "$") @DS @DX _ s: String) {
        Foundation::write(STDOUT_FILENO, s, s.count)
        cpu.reg.AL.setValue(("$" as Character).asciiValue!);
    }

    @Interrupt(function: 0x0B, description: "Get STDIN status")
    private func getStdinStatus(_ cpu: CPU) {
        cpu.reg.AL.setValue(0x00) // [MEM.EXE 4.01]
    }
}
