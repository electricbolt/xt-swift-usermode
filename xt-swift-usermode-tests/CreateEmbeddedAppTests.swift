// CreateEmbeddedAppTests.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Testing
import Foundation

class CreateEmbeddedAppTests: IntegrationTest {

    @Test func testCompile() throws {
        try copy("Microsoft Assembler 5.10", "MASM.EXE")
        let appResult = try execute(["app", "MASM.EXE", "masm"])

        #expect(appResult.exitCode == 255)

        let appExpected =
            """
            Creating app masm
            Signing app masm
            Making app executable masm\n
            """

        #expect(appResult.stdout == appExpected)

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

        try write("HELLO.ASM", contents)
        let masmResult = try xt_swift_usermode_tests.execute("\(tempDir)masm", ["HELLO.ASM,HELLO.OBJ,,;"], tempDir)

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
    }
}
