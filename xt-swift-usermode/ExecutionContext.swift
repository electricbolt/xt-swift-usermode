// ExecutionContext.swift
// XT Copyright © 2026; Electric Bolt Limited.

import XTSwiftCPU8088

public class ExecutionContext {

    public let ivt: InterruptVectorTable
    public let bda: BIOSDataArea
    public let env: EnvironmentVariables
    public let dos: DOSVariables
    public let err: DOSErrorTable
    public var mcb: MCB!
    public var psp: PSP!
    public let program: Program
    public let end: EndOfMemory
    public let memoryManager: MemoryManager
    public let trace: Trace
    public var spaces = [MemorySpace]()

    public init(_ memory: Memory, _ trace: Trace) {
        self.trace = trace

        let paragraph = ParagraphAlloc()
        self.ivt = InterruptVectorTable(memory, paragraph); spaces.append(ivt)
        self.bda = BIOSDataArea(memory, paragraph); spaces.append(bda)
        self.dos = DOSVariables(memory, paragraph); spaces.append(dos)
        self.err = DOSErrorTable(memory, paragraph); spaces.append(err)
        self.env = EnvironmentVariables(memory, paragraph); spaces.append(env)
        self.end = EndOfMemory(memory, paragraph)
        self.program = Program(memory, paragraph); spaces.append(program)
        spaces.append(end)
        self.memoryManager = MemoryManager(memory, program)
    }

    public func dump() {
        if trace.isTracing() {
            for space in spaces {
                space.dump()
            }
            print()
        }
    }

    public func invalidMemoryAccess(_ cpu: CPU, _ memoryAddress: SegOfs, _ permissionMask: UInt8, _ value: UInt8) {
        for space in spaces {
            if space.contains(memoryAddress) {
                space.invalidMemoryAccess(cpu, trace, memoryAddress, permissionMask, value)
            }
        }
    }
}
