// Misc.swift
// XT Copyright © 2025; Electric Bolt Limited.

import Foundation
import InterruptMacroPlugin
import XTSwiftCPU8088

public class Misc {

    @Interrupt(function: 0x33, subfunction: 0x01, description: "Set extended break checking state")
    func setExtendedBreakChecking(_ cpu: CPU, @DL _ state: Bool) {
        // Do nothing, as the user can always terminate the app using ^C.
    }

    @Interrupt(function: 0x37, subfunction: 0x00, description: "Get switch character")
    func getSwitchCharacter(_ cpu: CPU) {
        cpu.reg.AL.setValue(0x00)
        cpu.reg.DL.setValue(UInt8(ascii: "/"))
    }

    @Interrupt(function: 0x30, description: "Get DOS version")
    func getDOSVersion(_ cpu: CPU) {
        cpu.reg.AX.setValue(0x0004) // Report version DOS 4.00
        cpu.reg.BX.setValue(0x0)
        cpu.reg.CX.setValue(0x0)
    }

    @Interrupt(function: 0x38, description: "Get country specific information")
    func getCountryInformation(_ cpu: CPU, @DS @DX _ address: SegOfs) {
        cpu.memory.fill(address, 0x29, 0x00)

        // 00h WORD Date format. 0=USA.

        // 02h 5 BYTEs ASCIZ currency symbol string.
        var address = SegOfs(cpu.reg.DS, cpu.reg.DX.getValue() &+ 0x02)
        cpu.memory.writeByte(address, UInt8(ascii: "$"))

        // 07h 2 BYTEs ASCIZ thousands separator.
        address = SegOfs(cpu.reg.DS, cpu.reg.DX.getValue() &+ 0x07)
        cpu.memory.writeByte(address, UInt8(ascii: ","))

        // 09h 2 BYTEs ASCIZ decimal separator.
        address = SegOfs(cpu.reg.DS, cpu.reg.DX.getValue() &+ 0x09)
        cpu.memory.writeByte(address, UInt8(ascii: "."))

        // 0Bh 2 BYTEs ASCIZ date separator.
        address = SegOfs(cpu.reg.DS, cpu.reg.DX.getValue() &+ 0x0B)
        cpu.memory.writeByte(address, UInt8(ascii: "/"))

        // 0Dh 2 BYTEs ASCIZ time separator.
        address = SegOfs(cpu.reg.DS, cpu.reg.DX.getValue() &+ 0x0D)
        cpu.memory.writeByte(address, UInt8(ascii: ":"))

        // 0Fh BYTE currency format. 0=Currency symbol precedes value.

        // 10h 2 BYTE Number of digits.
        address = SegOfs(cpu.reg.DS, cpu.reg.DX.getValue() &+ 0x10)
        cpu.memory.writeByte(address, 0x02)

        // 11h BYTE time format. 0=12 hour clock.

        // 12h DWORD address of case map routine (FAR call, AL = character to map to uppercase [>= 80h])

        // 16h ASCIZ data-list separator.
        address = SegOfs(cpu.reg.DS, cpu.reg.DX.getValue() &+ 0x16)
        cpu.memory.writeByte(address, UInt8(ascii: ","))

        // 18h 10 BYTEs reserved.
    }

    @Interrupt(function: 0x52, description: "Get List of Lists")
    func getListOfLists(_ cpu: CPU, _ context: ExecutionContext) {
        let address = context.dos.getStartOfDOSVariables()
        cpu.reg.ES.setValue(address.getSegment())
        cpu.reg.BX.setValue(address.getOffset())
    }

    @Interrupt(function: 0x62, description: "Get current PSP")
    func getCurrentPSP(_ cpu: CPU, _ context: ExecutionContext) {
        cpu.reg.BX.setValue(context.psp!.segment)
    }

    @Interrupt(function: 0x63, subfunction: 0x00, description: "Get lead byte table address")
    func getLeadByteTableAddress(_ cpu: CPU) {
        // Return the BIOS data area - always zero'd out.
        // 00h 2 BYTEs 00,00 end flag.
        cpu.reg.DS.setValue(0x0400)
        cpu.reg.SI.setValue(0x0000)
    }
}
