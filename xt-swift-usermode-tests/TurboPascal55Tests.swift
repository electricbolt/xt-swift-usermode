// TurboPascal55Tests.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Testing
import Foundation

class TurboPascal55Tests: IntegrationTest {

    @Test func testNoCommandLineArguments() throws {
        do {
            try copy("Turbo Pascal 5.5", "TPC.EXE")
            try copy("Turbo Pascal 5.5", "TURBO.TPL")
        } catch {
            // Skip test if TPC.EXE and TURBO.TPL have not been added to the Turbo Pascal 5.5 directory.
            print("Skipping TurboPascal55Tests.testNoCommandLineArguments")
            return
        }
        let result = try execute(["run", "TPC.EXE"])

        #expect(result.exitCode == 0)

        let expected =
            """
            Turbo Pascal Version 5.5  Copyright (c) 1983,89 Borland International
            Syntax: TPC [options] filename [options]
            /B\tBuild all units\t\t/$A-\tNo word alignment
            /Dxxx\tDefine conditionals\t/$B+\tComplete boolean evaluation
            /Exxx\tEXE & TPU directory\t/$D-\tNo debug information
            /Fxxx\tFind run-time error\t/$E-\tNo 8087 emulation
            /GS\tMap file with segments\t/$F+\tForce FAR calls
            /GP\tMap file with publics\t/$I-\tNo I/O checking
            /GD\tDetailed map file\t/$L-\tNo local debug symbols
            /Ixxx\tInclude directories\t/$Mxxx\tMemory allocation parameters
            /L\tLink buffer on disk\t/$N+\t8087 code generation
            /M\tMake modified units\t/$O+\tOverlays allowed
            /Oxxx\tObject directories\t/$R+\tRange checking
            /Q\tQuiet compile\t\t/$S-\tNo stack checking
            /Txxx\tTurbo directories\t/$V-\tNo var-string checking
            /Uxxx\tUnit directories
            /V\tEXE debug information\n
            """.replacingOccurrences(of: "\n", with: "\r\n")

        #expect(result.stdout == expected)
    }

    @Test func testCompile() throws {
        // TPC.EXE

        let contents =
            """
            program HelloWorld(input, output);

            begin
              writeln('Hello, world!');
            end.
            """

        do {
            try copy("Turbo Pascal 5.5", "TPC.EXE")
            try copy("Turbo Pascal 5.5", "TURBO.TPL")
        } catch {
            // Skip test if TPC.EXE and TURBO.TPL have not been added to the Turbo Pascal 5.5 directory.
            print("Skipping TurboPascal55Tests.testCompile")
            return
        }
        try write("HELLO.PAS", contents)
        let tpcResult = try execute(["run", "TPC.EXE", "HELLO.PAS"])

        #expect(tpcResult.exitCode == 0)

        let tpcExpected =
            """
            Turbo Pascal Version 5.5  Copyright (c) 1983,89 Borland International
            HELLO.PAS(0)\rHELLO.PAS(0)\rHELLO.PAS(5)\rHELLO.PAS(5)
            5 lines, 1712 bytes code, 646 bytes data.\n
            """.replacingOccurrences(of: "\n", with: "\r\n")

        #expect(tpcResult.stdout == tpcExpected)

        // HELLO.EXE

        let helloResult = try execute(["run", "HELLO.EXE"])

        #expect(helloResult.exitCode == 0)

        let helloExpected =
            """
            Hello, world!\n
            """.replacingOccurrences(of: "\n", with: "\r\n")

        #expect(helloResult.stdout == helloExpected)
    }
}
