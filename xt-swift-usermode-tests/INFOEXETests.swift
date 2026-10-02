// INFOEXETests.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Testing
import Foundation

class INFOEXETests: IntegrationTest {

    @Test func testNoCommandLineArguments() throws {
        try copy("INFOEXE 1.0", "INFOEXE.EXE")
        let result = try execute(["run", "INFOEXE.EXE"])

        #expect(result.exitCode == 0)

        let expected =
            """
            INFOEXE.EXE  v1.00   (c) 1989 Fabrice BELLARD
            Information about an EXE file

            Usage: INFOEXE filename[.EXE]

            ╔═══════════════════════════════════════════════════════════════════════╗
            ║ This program was conceived and written by Fabrice BELLARD who decided ║
            ║ generously to make it FREEWARE.                                       ║
            ║ If you have any problems with or suggestions for this program,        ║
            ║ please write to:            Fabrice BELLARD                           ║
            ║                          451 chemin du mas de matour                  ║
            ║                              34790 GRABELS   (FRANCE)                 ║
            ║                                                                       ║
            ║ Translation to English by Mark Armbrust:  70 S. 31st Boulder CO 80303 ║
            ╚═══════════════════════════════════════════════════════════════════════╝\n
            """.replacingOccurrences(of: "\n", with: "\r\n")

        #expect(result.stdout == expected)
    }

    @Test func testRunINFOEXE() throws {
        try copy("INFOEXE 1.0", "INFOEXE.EXE")
        try copy("Microsoft Assembler 5.10", "MASM.EXE")
        let infoResult = try execute(["run", "INFOEXE.EXE", "MASM"])

        #expect(infoResult.exitCode == 0)

        let infoExpected =
            """
            INFOEXE.EXE  v1.00   (c) 1989 Fabrice BELLARD
            Information about an EXE file

            Examining MASM.EXE

                                                       Decimal            Hex

            Length on disk (bytes)                      110703       0001B06F
            Length of code in the EXE (bytes)           110703       0001B06F

            Min. memory requested (paragraphs)             714           02CA
            Max. memory requested (paragraphs)           65535           FFFF

            SS:SP                                                   1BD4:0080
            CS:IP                                                   1A84:0010

            Number of relocation entries                     0           0000
            Start of relocation table                       30           001E
            Length of header (paragraphs)                   32           0020

            Num. of overlays                                 0           0000\n\n
            """.replacingOccurrences(of: "\n", with: "\r\n")

        #expect(infoResult.stdout == infoExpected)
    }

}
