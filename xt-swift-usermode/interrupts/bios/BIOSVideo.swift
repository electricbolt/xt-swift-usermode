// BiosVideo.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Foundation
import InterruptMacroPlugin
import XTSwiftCPU8088

/// XT emulates a MDA (text only 80x25) display adapter, so most functions in this class do nothing.

public class BIOSVideo {

    /// Specify the display mode for the currently active display adapter.

    @Interrupt(interrupt: 0x10, function: 0x00, description: "Set video mode")
    func setVideoMode(_ cpu: CPU, @AL _ mode: UInt8) {
        // do nothing.
    }

    /// Specify the starting and ending scan lines to be occupied by the hardware cursor in text modes.

    @Interrupt(interrupt: 0x10, function: 0x01, description: "Set text-mode cursor shape")
    func setTextModeCursorShape(_ cpu: CPU, @CH _ top: UInt8, @CL _ bottom: UInt8) {
        // do nothing.
    }

    @Interrupt(interrupt: 0x10, function: 0x02, description: "Set cursor position")
    func setCursorPosition(_ cpu: CPU, @BH _ page: UInt8, @DH _ row: UInt8, @DL _ column: UInt8) {
        // do nothing.
    }

    @Interrupt(interrupt: 0x10, function: 0x03, description: "Get cursor position")
    func getCursorPositionAndSize(_ cpu: CPU, @BH _ page: UInt8, @DH _ row: UInt8, @DL _ column: UInt8) {
        cpu.reg.CH.setValue(11) // Start scan line.
        cpu.reg.CL.setValue(12) // End scan line.
        cpu.reg.DH.setValue(0) // Row.
        cpu.reg.DL.setValue(0) // Column.
    }

    /// Specify which of possibly multiple display pages will be visible.

    @Interrupt(interrupt: 0x10, function: 0x05, description: "Select active display page")
    func selectActiveDisplayPage(_ cpu: CPU, @AL _ page: UInt8) {
        // do nothing.
    }

    @Interrupt(interrupt: 0x10, function: 0x06, description: "Scroll window up")
    func scrollWindowUp(_ cpu: CPU, @AL _ lines: UInt8, @BH _ attribute: UInt8, @CX _ topLeft: UInt16, @DX _ bottomRight: UInt16) {
        // do nothing.
    }

    @Interrupt(interrupt: 0x10, function: 0x07, description: "Scroll window down")
    func scrollWindowDown(_ cpu: CPU, @AL _ lines: UInt8, @BH _ attribute: UInt8, @CX _ topLeft: UInt16, @DX _ bottomRight: UInt16) {
        // do nothing.
    }

    @Interrupt(interrupt: 0x10, function: 0x08, description: "Read character and attribute at cursor position")
    func readCharacterAndAttributeAtCursorPosition(_ cpu: CPU, @BH _ page: UInt8) {
        cpu.reg.AL.setValue(Character(" ").asciiValue!)
        cpu.reg.AH.setValue(0x07) // (Normal): White foreground colour, black background colour.
    }

    @Interrupt(interrupt: 0x10, function: 0x09, description: "Write character and attribute at cursor position")
    func writeCharacterAndAttributeAtCursorPosition(_ cpu: CPU, @BH _ page: UInt8, @AL _ char: Character, @BL _ attribute: UInt8, @CX _ count: UInt16) {
        for _ in 0..<count {
            print(char, terminator: "")
        }
    }

    @Interrupt(interrupt: 0x10, function: 0x0A, description: "Write character only at cursor position")
    func writeCharacterOnlyAtCursorPosition(_ cpu: CPU, @BH _ page: UInt8, @AL _ char: Character, @CX _ count: UInt16) {
        for _ in 0..<count {
            print(char, terminator: "")
        }
    }

    /// Display a character on the screen, advancing the cursor and scrolling the screen as necessary.

    @Interrupt(interrupt: 0x10, function: 0x0E, description: "Teletype output")
    func teletypeOutput(_ cpu: CPU, @BL _ page: UInt8, @AL _ char: Character) {
        print(char, terminator: "")
    }

    @Interrupt(interrupt: 0x10, function: 0x0F, description: "Get current video mode")
    func getCurrentVideoMode(_ cpu: CPU) {
        cpu.reg.AH.setValue(80) // Number of character columns.
        cpu.reg.AL.setValue(0x07) // Display mode = 80x25 monochrome.
        cpu.reg.BH.setValue(0) // Active page.
    }
}
