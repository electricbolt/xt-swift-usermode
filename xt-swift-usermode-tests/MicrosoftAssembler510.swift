// MicrosoftAssembler510Tests.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Testing
import Foundation

class MicrosoftAssembler510Tests: IntegrationTest {

    @Test func testNoCommandLineArguments() throws {
        try copy("Microsoft Assembler 5.10", "MASM.EXE")
        let result = try execute(["run", "MASM.EXE"])

        #expect(result.exitCode == 254)

        let expected =
            """
            Microsoft (R) Macro Assembler Version 5.10 
            Copyright (C) Microsoft Corp 1981, 1988.  All rights reserved.

            Source filename [.ASM]: 
            """.replacingOccurrences(of: "\n", with: "\r\n")

        #expect(result.stdout == expected)
    }

    @Test func testCompile() throws {
        // MASM.EXE

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

        try copy("Microsoft Assembler 5.10", "MASM.EXE")
        try write("HELLO.ASM", contents)
        let masmResult = try execute(["run", "MASM.EXE", "HELLO.ASM,HELLO.OBJ,,;"])

        #expect(masmResult.exitCode == 0)

        let masmExpected =
            """
            Microsoft (R) Macro Assembler Version 5.10 
            Copyright (C) Microsoft Corp 1981, 1988.  All rights reserved.


              47564 + 859263 Bytes symbol space free

                  0 Warning Errors
                  0 Severe  Errors\n
            """.replacingOccurrences(of: "\n", with: "\r\n")

        #expect(masmResult.stdout == masmExpected)

        // LINK.EXE

        try copy("Microsoft Linker 3.65", "LINK.EXE")
        let linkResult = try execute(["run", "LINK.EXE", "HELLO.OBJ,HELLO.EXE,,,"])

        #expect(linkResult.exitCode == 0)

        let linkExpected =
            """
            
            Microsoft (R) Overlay Linker  Version 3.65   
            Copyright (C) Microsoft Corp 1983-1988.  All rights reserved.

            LINK : warning L4021: no stack segment\n
            """.replacingOccurrences(of: "\n", with: "\r\n")

        #expect(linkResult.stdout == linkExpected)

        // HELLO.EXE

        let helloResult = try execute(["run", "HELLO.EXE"])

        #expect(helloResult.exitCode == 0)

        let helloExpected =
            """
            Hello, world!\r
            """

        #expect(helloResult.stdout == helloExpected)
    }
}
