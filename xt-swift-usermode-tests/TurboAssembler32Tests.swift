// TurboAssembler32Tests.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Testing
import Foundation

class TurboAssembler32Tests: IntegrationTest {

    @Test func testNoCommandLineArguments() throws {
        do {
            try copy("Turbo Assembler 3.2", "TASM.EXE")
        } catch {
            // Skip test if TASM.EXE has not been added to the Turbo Assembler 3.2 directory.
            print("Skipping TurboAssembler32Tests.testNoCommandLineArguments")
            return
        }
        let result = try execute(["run", "TASM.EXE"])

        #expect(result.exitCode == 0)

        let expected =
            """
            Turbo Assembler  Version 3.2  Copyright (c) 1988, 1992 Borland International
            Syntax:  TASM [options] source [,object] [,listing] [,xref]
            /a,/s         Alphabetic or Source-code segment ordering
            /c            Generate cross-reference in listing
            /dSYM[=VAL]   Define symbol SYM = 0, or = value VAL
            /e,/r         Emulated or Real floating-point instructions
            /h,/?         Display this help screen
            /iPATH        Search PATH for include files
            /jCMD         Jam in an assembler directive CMD (eg. /jIDEAL)
            /kh#          Hash table capacity # symbols
            /l,/la        Generate listing: l=normal listing, la=expanded listing
            /ml,/mx,/mu   Case sensitivity on symbols: ml=all, mx=globals, mu=none
            /mv#          Set maximum valid length for symbols
            /m#           Allow # multiple passes to resolve forward references
            /n            Suppress symbol tables in listing
            /os,/o,/op,/oiObject code: standard, standard w/overlays, Phar Lap, or IBM
            /p            Check for code segment overrides in protected mode
            /q            Suppress OBJ records not needed for linking
            /t            Suppress messages if successful assembly
            /uxxxx        Set version emulation, version xxxx
            /w0,/w1,/w2   Set warning level: w0=none, w1=w2=warnings on
            /w-xxx,/w+xxx Disable (-) or enable (+) warning xxx
            /x            Include false conditionals in listing
            /z            Display source line with error message
            /zi,/zd,/zn   Debug info: zi=full, zd=line numbers only, zn=none
            """.replacingOccurrences(of: "\n", with: "\r\n")

        #expect(result.stdout == expected)
    }

    @Test func testCompile() throws {
        // TASM.EXE

        let contents =
            """
            code segment
            assume cs:code
            assume ds:data

              mov   ax, data
              mov   ds, ax

              mov   dx, offset hello
              mov   ah, 09h
              int   21h
            
              mov   ah, 00h
              int   21h

            code ends

            data segment
              hello db 'Hello, world!', 13, 10, '$'
            data ends
             
            END
            """

        do {
            try copy("Turbo Assembler 3.2", "TASM.EXE")
        } catch {
            // Skip test if TASM.EXE has not been added to the Turbo Assembler 3.2 directory.
            print("Skipping TurboAssembler32Tests.testCompile")
            return
        }
        try write("HELLO.ASM", contents)
        let tasmResult = try execute(["run", "TASM.EXE", "HELLO.ASM"])

        #expect(tasmResult.exitCode == 0)

        let tasmExpected =
            """
            Turbo Assembler  Version 3.2  Copyright (c) 1988, 1992 Borland International

            Assembling file:   HELLO.ASM
            Error messages:    None
            Warning messages:  None
            Passes:            1
            Remaining memory:  857k
            \n
            """.replacingOccurrences(of: "\n", with: "\r\n")

        #expect(tasmResult.stdout == tasmExpected)

        // TLINK.EXE

        try copy("Turbo Linker 3.0.1", "TLINK.EXE")
        let tlinkResult = try execute(["run", "TLINK.EXE", "HELLO.OBJ"])

        #expect(tlinkResult.exitCode == 0)

        let tlinkExpected =
            """
            Turbo Link  Version 3.01 Copyright (c) 1987, 1990 Borland International
            Warning: No stack\n
            """.replacingOccurrences(of: "\n", with: "\r\n")

        #expect(tlinkResult.stdout == tlinkExpected)

        // HELLO.EXE

        let helloResult = try execute(["run", "HELLO.EXE"])

        #expect(helloResult.exitCode == 0)

        let helloExpected =
            """
            Hello, world!\r
            """.replacingOccurrences(of: "\n", with: "\r\n")

        #expect(helloResult.stdout == helloExpected)
    }

}
