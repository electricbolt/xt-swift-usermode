// main.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation
import InterruptMacroPlugin
import XTSwiftCPU8088

/// Main entry point to XT.

let main = Main(CommandLineParser(Array(CommandLine.arguments.dropFirst())))
main.runEmbeddedProgram()
main.parse()

class Main {

    init(_ commandLine: CommandLineParser) {
        self.commandLine = commandLine
    }

    func runEmbeddedProgram() {
        let program: [UInt8] = EmbeddedProgram.getProgram()
        if !program.isEmpty {
            var args = ""
            while commandLine.hasNext() {
                if !args.isEmpty {
                    args += " "
                }
                args += commandLine.next()!
            }

            let runner = ProgramRunner(program: program, commandLine: args)
            runner.loadAndExecute()
            exit(255)
        }
    }

    func parse() {
        if commandLine.hasNext() {
            let argument: String = commandLine.next()!
            switch argument {
                case "help": parseHelp()
                case "int": parseInt()
                case "run": parseRun()
                case "app": parseApp()
                default: haltSyntax(argument + " not recognized")
            }
        }
        haltSyntax("")
    }

    // MARK: - Internal

    private var traceCPU = false
    private var traceInterrupt = false
    private var traceFile = ""
    private var signingIdentity = "-"
    private var emulatedProgramPath = ""
    private var emulatedProgramArgs = ""
    private var hostWorkingDir = ""
    private let commandLine: CommandLineParser

    private func printAppVersion() {
        let currentYear = Calendar.current.component(.year, from: Date())
        print("XT version \(appVersion); Copyright © 2025-\(currentYear); Electric Bolt Limited.")
    }

    private func haltSyntax(_ message: String) {
        printAppVersion()
        print("Syntax:        xt help [run|int]")
        print("               xt run [options] program [program-args]")
        print("               xt app [options] program")
        print("               xt int")
        if !message.isEmpty {
            print()
            print("error: " + message)
        }
        exit(255)
    }

    private func haltSyntaxRun(_ message: String) {
        printAppVersion()
        print("Syntax:        xt run [-tc -ti file] [-c dir] program [program-args]")
        print("               Run a .EXE or .COM command line MS-DOS program on your host")
        print("               system.")
        print("-tc -ti file = Trace CPU and/or interrupts to the tracing host file specified.")
        print("-c dir       = The host directory that will be the root of the emulated C: drive")
        print("               If not specified then the current working directory will be used.")
        print("program      = The .EXE or .COM command line MS-DOS program you want to run.")
        print("               You can optionally prefix with emulated path.")
        print("program-args = Optional arguments for the MS-DOS program, max 127 characters.")
        print()
        print("The exit code will be 255 if XT terminates the program due to an error,")
        print("otherwise the exit code will be the exit code of the MS-DOS program.")
        if !message.isEmpty {
            print()
            print("error: " + message)
        }
        exit(255)
    }

    private func haltSyntaxInt(_ message: String) {
        printAppVersion()
        print("Syntax:        xt int [-md]")
        print("               Output the list of interrupts that are implemented by this")
        print("               version of XT for the run command.")
        print("-md          = Output interrupts with markdown.")
        if !message.isEmpty {
            print()
            print("error: " + message)
        }
        exit(255)
    }

    private func haltSyntaxApp(_ message: String) {
        printAppVersion()
        print("Syntax:        xt app [-s identity] program output")
        print("               Converts the .EXE or .COM command line MS-DOS program into a")
        print("               native macOS command line app.")
        print("-s identity  = Codesign with the specific certificate identity from your")
        print("               Keychain. If -s not specified, will sign the binary locally with")
        print("               adhoc signing.")
        print("program      = Input .EXE or COM command line MS-DOS program.")
        print("output       = Output native macOS command line app.")
        if !message.isEmpty {
            print()
            print("error: " + message)
        }
        exit(255)
    }

    private func run() {
        if hostWorkingDir.isEmpty {
            hostWorkingDir = FileManager.default.currentDirectoryPath
        }
        if !hostWorkingDir.hasSuffix("/") {
            hostWorkingDir += "/"
        }

        let runner = ProgramRunner(programPath: emulatedProgramPath,
            commandLine: emulatedProgramArgs, hostWorkingDir: hostWorkingDir,
            traceCPU: traceCPU, traceInterrupt: traceInterrupt, traceFile: traceFile)
        runner.loadAndExecute()
    }

    private func parseInt() {
        var markdown = false
        if let argument: String = commandLine.peek() {
            if argument == "-md" {
                markdown = true
            } else {
                haltSyntaxInt(argument + " argument not recognized")
            }
        }
        let interrupts = Interrupts()
        interrupts.printInterrupts(markdown)
        exit(255)
    }

    private func parseCodeSigning() {
        _ = commandLine.next() // -s
        if !commandLine.hasNext() {
            haltSyntaxApp("expecting certificate identity argument")
        } else {
            let argument = commandLine.next()
            signingIdentity = argument!
        }
    }

    private func parseApp() {
        if !commandLine.hasNext() {
            haltSyntaxApp("expecting program argument")
        }
        let argument: String = commandLine.peek()!
        if argument == "-s" {
            parseCodeSigning()
        }
        let program: String? = commandLine.next()
        if program == nil {
            haltSyntaxApp("expecting program argument")
        }
        let output: String? = commandLine.next()
        if output == nil {
            haltSyntaxApp("expecting output argument")
        }
        EmbeddedProgram.createApp(from: program!, signingIdentity, output!)
        exit(255)
    }

    private func parseTraceInterrupt() {
        traceInterrupt = true
        let argument: String? = commandLine.next()
        if argument == nil {
            haltSyntaxRun("expecting tracing host file argument")
        } else if argument!.hasPrefix("-") {
            haltSyntaxRun(argument! + " argument not recognized")
        } else {
            traceFile = argument!
        }
    }

    private func parseTraceCPU() {
        traceCPU = true
        let argument: String? = commandLine.next()
        if argument == nil {
            haltSyntaxRun("expecting -ti or tracing host file argument")
        } else if argument! == "-ti" {
            parseTraceInterrupt()
        } else if argument!.hasPrefix("-") {
            haltSyntaxRun(argument! + " argument not recognized")
        } else {
            traceFile = argument!
        }
    }

    private func parseTraceOptions() {
        let argument: String = commandLine.next()!
        if argument == "-tc" {
            parseTraceCPU()
        } else if argument == "-ti" {
            parseTraceInterrupt()
        } else {
            haltSyntaxRun(argument + " argument not recognized")
        }
    }

    private func parseRootDirectory() {
        _ = commandLine.next() // skip over -c argument.
        let argument: String? = commandLine.next()
        if argument == nil {
            haltSyntaxRun("expecting host root directory argument")
        } else if argument!.hasPrefix("-") {
            haltSyntaxRun("expecting host root directory argument")
        } else {
            hostWorkingDir = argument!
        }
    }

    private func parseRun() {
        if !commandLine.hasNext() {
            haltSyntaxRun("expecting program argument")
        }

        // Options.
        var argument: String = commandLine.peek()!
        if argument.hasPrefix("-t") {
            parseTraceOptions()
        }

        if !commandLine.hasNext() {
            haltSyntaxRun("expecting program argument")
        }

        argument = commandLine.peek()!
        if argument == "-c" {
            parseRootDirectory()
        }

        if !commandLine.hasNext() {
            haltSyntaxRun("expecting program argument")
        }

        // Program (mandatory).
        argument = commandLine.next()!
        if argument.hasPrefix("-") {
            haltSyntaxRun(argument + " not recognized")
        } else {
            emulatedProgramPath = argument
        }

        // Program args (optional).
        var buf = ""
        while commandLine.hasNext() {
            if !buf.isEmpty {
                buf += " "
            }
            buf += commandLine.next()!
        }
        emulatedProgramArgs = buf

        run()

        exit(255)
    }

    private func parseHelp() {
        if commandLine.hasNext() {
            let argument: String = commandLine.next()!
            switch argument {
                case "run": haltSyntaxRun("")
                case "int": haltSyntaxInt("")
                case "app": haltSyntaxApp("")
                default: haltSyntax(argument + " not recognized")
            }
        }
        haltSyntax("")
    }
}
