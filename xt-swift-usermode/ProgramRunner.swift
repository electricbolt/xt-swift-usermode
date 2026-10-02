// ProgramRunner.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088

public class ProgramRunner {

    /// Initializer for embedded MS-DOS program

    public convenience init(program: [UInt8], commandLine: String) {
        var hostWorkingDir: String = FileManager.default.currentDirectoryPath
        if !hostWorkingDir.hasSuffix("/") {
            hostWorkingDir += "/"
        }
        let directoryTranslation = DirectoryTranslation(hostWorkingDir)

        self.init(program, "EMULATED.EXE", commandLine, directoryTranslation)
    }

    /// Initializer for MS-DOS program being run using "xt run" command

    public convenience init(programPath: String, commandLine: String, hostWorkingDir: String, traceCPU: Bool,
                            traceInterrupt: Bool, traceFile: String) {
        do {
            let directoryTranslation = DirectoryTranslation(hostWorkingDir)
            let programPath: String = directoryTranslation.emulatedPathToHostPath(programPath)
            let program = [UInt8](try Data(contentsOf: URL(fileURLWithPath: programPath)))

            self.init(program, programPath, commandLine, directoryTranslation, traceCPU, traceInterrupt, traceFile)
        } catch {
            print("The program \(programPath) could not be read.")
            exit(255)
        }
    }

    func loadAndExecute() {
        context.env.writeVariable("PATH", "C:\\")
        context.env.writeExecutablePath(directoryTranslation.hostPathToEmulatedPath(programPath))

        if (program.count < 0x1C) || program[0x00] != UInt8(ascii: "M") || program[0x01] != UInt8(ascii: "Z") {
            guard program.count > 0 else {
                print("The program \(programPath) is not executable (length 0).")
                exit(255)
            }

            // COM file
            let freeAllocSize: Int = context.program.size - MCB.allocationSize

            context.mcb = try! context.memoryManager.alloc(algorithm: .firstFit, sizeInBytes: freeAllocSize)
            context.psp = PSP(cpu.memory, context.mcb.segment + 1)
            context.psp.writeNextSegment(UInt16(context.mcb.segment &+ context.mcb.readSize()))

            let codeSegment: UInt16 = context.psp.segment
            let startLinearAddress = SegOfs(codeSegment, 0x100).toLinearAddress()
            cpu.memory.putLinearData(startLinearAddress, program, 0, program.count)

            cpu.reg.SP.setValue(0xFFFE)
            cpu.reg.SS.setValue(codeSegment)
            cpu.reg.IP.setValue(0x0100)
            cpu.reg.CS.setValue(codeSegment)
        } else {
            // EXE file
            let header = EXE(program)

            let totalFileSize: Int
            if header.getLastPageSize() == 0 {
                totalFileSize = header.getPages() * 512
            } else {
                totalFileSize = ((header.getPages() - 1) * 512) + header.getLastPageSize()
            }
            let headerSize: Int = header.getParagraphsInHeader() * 16
            let codeSize: Int = totalFileSize - headerSize
            let minAllocSize: Int = codeSize + header.getParagraphsForUninitializedData() * 16 + PSP.allocationSize
            let maxAllocSize: Int = codeSize + header.getParagraphsToConstrainMemory() * 16 + PSP.allocationSize

            if header.getParagraphsForUninitializedData() == 0 && header.getParagraphsToConstrainMemory() == 0 {
                // Load high
                print("Load high not implemented")
                exit(255)
            }

            let freeAllocSize: Int = context.program.size - MCB.allocationSize
            if minAllocSize > freeAllocSize {
                print("Not enough memory to load program \(minAllocSize) bytes required, \(freeAllocSize) bytes free")
                exit(255)
            }
            let allocSize: Int = min(maxAllocSize, freeAllocSize)

            context.mcb = try! context.memoryManager.alloc(algorithm: .firstFit, sizeInBytes: allocSize)
            context.psp = PSP(cpu.memory, context.mcb.segment + 1)
            context.psp.writeNextSegment(UInt16(context.mcb.segment &+ context.mcb.readSize()))

            let codeSegment: UInt16 = context.psp.segment + 16
            let startLinearAddress = SegOfs(codeSegment, 0).toLinearAddress()
            cpu.memory.putLinearData(startLinearAddress, program, headerSize, codeSize)

            // Relocations
            for i in 0..<header.getRelocationEntries() {
                let address: SegOfs = header.relocationItem(i)
                let relocated = SegOfs(address.getSegment() &+ codeSegment, address.getOffset())
                let value = cpu.memory.readWord(relocated)
                cpu.memory.writeWord(relocated, value &+ codeSegment)
            }

            cpu.reg.SP.setValue(UInt16(header.getSP()))
            cpu.reg.SS.setValue(UInt16(header.getRelativeSS()) &+ codeSegment)
            cpu.reg.IP.setValue(UInt16(header.getIP()))
            cpu.reg.CS.setValue(UInt16(header.getRelativeCS()) &+ codeSegment)
        }

        context.memoryManager.setOwner(owner: context.psp.segment)
        context.mcb.writeOwner(context.psp.segment)
        context.mcb.writeProgram(String(getProgramName().split(separator: ".").first!))
        context.dos.writeFirstMCBSegment(context.mcb.segment)
        context.spaces.insert(context.mcb, at: context.spaces.count - 1)
        context.spaces.insert(context.psp, at: context.spaces.count - 1)

        context.psp.writeEnvironment(context.env.segment)
        context.psp.writeCommandLine(commandLine)

        var filename1 = ""
        var filename2 = ""
        if !commandLine.isEmpty {
            let files: [String] = commandLine.components(separatedBy: " ")
            if files.count >= 1 {
                filename1 = FileIO.getFilenameFromPath(files[0]).uppercased()
                if files.count >= 2 {
                    filename2 = FileIO.getFilenameFromPath(files[1]).uppercased()
                }
            }
        }
        context.psp.writeFilename(1, "C", filename1)
        context.psp.writeFilename(2, "C", filename2)

        cpu.reg.AX.setValue(0x0202) // AL,AH = Drive numbers for the first and second FCB
        cpu.reg.DS.setValue(context.psp.segment) // Segment for start of PSP
        cpu.reg.ES.setValue(context.psp.segment) // Segment for start of PSP

        context.dump()

        cpu.execute()
    }

    // MARK: - Internal

    private let programPath: String
    private let program: [UInt8]
    private let commandLine: String
    private let interrupts: Interrupts
    private let directoryTranslation: DirectoryTranslation
    private var context: ExecutionContext!
    private var trace: Trace!
    private var cpu: CPU!
    private var fetchCounter = 0

    /// Common initializer

    private init(_ program: [UInt8], _ programPath: String, _ commandLine: String,
                 _ directoryTranslation: DirectoryTranslation, _ traceCPU: Bool = false,
                 _ traceInterrupt: Bool = false, _ traceFile: String = "") {
        self.directoryTranslation = directoryTranslation
        self.programPath = directoryTranslation.emulatedPathToHostPath(programPath)
        self.program = program
        self.commandLine = commandLine
        self.interrupts = Interrupts()
        self.cpu = CPU(delegate: self, hasPermissions: true, zeroMemory: true)
        self.trace = Trace(cpu, traceCPU, traceInterrupt, traceFile)
        self.context = ExecutionContext(cpu.memory, trace)
    }

    /// Returns the program name.
    ///
    /// Example: "C:\BIN\TASM.EXE" ‣ "TASM.EXE"

    private func getProgramName() -> String {
        if let index = programPath.lastIndex(of: "/") {
            let index = programPath.index(after: index)
            return String(programPath[index...])
        }
        return programPath
    }

    private func fetched() {
        if fetchCounter % 1000 == 0 {
            context.bda.updateTimerTick()
        }
        fetchCounter &+= 1
    }
}

extension ProgramRunner: CPUDelegate {

    public func fetched8(_ cpu: CPU, _ value: UInt8, _ instructionCount: UInt64) {
        trace.fetched8(value, instructionCount)
        fetched()
    }

    public func fetched16(_ cpu: CPU, _ value: UInt16, _ instructionCount: UInt64) {
        trace.fetched16(value, instructionCount)
        fetched()
    }

    public func interrupt(_ cpu: CPU, _ interrupt: UInt8) {
        interrupts.execute(cpu, interrupt, trace, directoryTranslation, context)
        cpu.reg.IP.setValue(cpu.pop16())
        cpu.reg.CS.setValue(cpu.pop16())
        _ = cpu.pop16() // flags should be passed through.
    }

    public func halt(_ cpu: CPU) {
        trace.log("CPU halted")
        trace.log(cpu.reg.description)
        print("CPU halted", to: &stderr)
        print(cpu.reg.description, to: &stderr)
        exit(255)
    }

    public func portRead8(_ cpu: CPU, _ address: UInt16) -> UInt8 {
        return 0
    }

    public func portWrite8(_ cpu: CPU, _ address: UInt16, _ value: UInt8) {
    }

    public func portRead16(_ cpu: CPU, _ address: UInt16) -> UInt16 {
        return 0
    }

    public func portWrite16(_ cpu: CPU, _ address: UInt16, _ value: UInt16) {
    }

    /// By default, this method will not be invoked - as all memory is marked read/write/execute. When diagnosing new application
    /// behavior, it's useful to observe memory areas being read, written or executed unexpectedly. See `DOSVariables.swift`
    /// for implementation guidance.

    public func invalidMemoryAccess(_ cpu: CPU, _ memoryAddress: SegOfs, _ permissionMask: UInt8, _ value: UInt8) {
        context.invalidMemoryAccess(cpu, memoryAddress, permissionMask, value)

        let message = "Invalid memory access \(cpu.memory.fromBitmask(permissionMask)) - \(memoryAddress) - \(String(format: "%02X", value))"
        trace.log(message)
        trace.log(cpu.reg.description)
        print(message, to: &stderr)
        print(cpu.reg.description + "\n", to: &stderr)
        cpu.memory.dump(memoryAddress)
        exit(255)
    }

    public func invalidOpcode(_ cpu: CPU, _ message: String) {
        trace.log(message)
        trace.log(cpu.reg.description)
        print(message, to: &stderr)
        print(cpu.reg.description, to: &stderr)
        exit(255)
    }
}
