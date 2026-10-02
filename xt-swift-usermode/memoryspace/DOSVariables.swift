// DOSVariables.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088

/// Variables that MS-DOS programs might access to function correctly. Programs would call "Get List of Lists" INT 21 function 52 to find this memory area.
/// The variables in the memory space are mostly specific MS-DOS 4.01, and therefore generally only useful to utilities that came with it.

public class DOSVariables: MemorySpace {

    public init(_ memory: Memory, _ paragraph: ParagraphAlloc) {
        super.init(memory, paragraph, MemoryLayout<_SysInitVars>.size, Mirror(reflecting: ofs))

        removePermission()
        allowPermission(ofs.firstMCBSegment, 2)
        allowPermission(ofs.deviceChain, 4)
        allowPermission(ofs.extendedMemorySize, 2)

        setWord(ofs.deviceChain, 0xFFFF)            // Ofs=0xFFFF indicates end of driver chain.
        setWord(ofs.deviceChain + 2, 0x0000)        // Seg=0x0000
        setWord(ofs.extendedMemorySize, 0x0000)     // 8088 CPU - no XMS memory.
    }

    public func getStartOfDOSVariables() -> SegOfs {
        return SegOfs(segment, UInt16(ofs.DPBChain))
    }

    public func writeFirstMCBSegment(_ segment: UInt16) {
        setWord(ofs.firstMCBSegment, segment)
    }

    // MARK: - Internal

    private struct Ofs {
        let reserved = MemoryLayout<_SysInitVars>.offset(of: \.reserved)!
        let firstMCBSegment = MemoryLayout<_SysInitVars>.offset(of: \.firstMCBSegment)! // Offset -2 when accessed from INT 21 function 52
        let DPBChain = MemoryLayout<_SysInitVars>.offset(of: \.DPBChain)! // Offset 0 when accessed from INT 21 function 52
        let SFTChain = MemoryLayout<_SysInitVars>.offset(of: \.SFTChain)!
        let clockDevice = MemoryLayout<_SysInitVars>.offset(of: \.clockDevice)!
        let conDevice = MemoryLayout<_SysInitVars>.offset(of: \.conDevice)!
        let maxSectorSize = MemoryLayout<_SysInitVars>.offset(of: \.maxSectorSize)!
        let bufferChain = MemoryLayout<_SysInitVars>.offset(of: \.bufferChain)!
        let CDSList = MemoryLayout<_SysInitVars>.offset(of: \.CDSList)!
        let FCBChain = MemoryLayout<_SysInitVars>.offset(of: \.FCBChain)!
        let FCBKeepCount = MemoryLayout<_SysInitVars>.offset(of: \.FCBKeepCount)!
        let blockDeviceCount = MemoryLayout<_SysInitVars>.offset(of: \.blockDeviceCount)!
        let CDSCount = MemoryLayout<_SysInitVars>.offset(of: \.CDSCount)!
        let deviceChain = MemoryLayout<_SysInitVars>.offset(of: \.deviceChain)!
        let nullDeviceAttribute = MemoryLayout<_SysInitVars>.offset(of: \.nullDeviceAttribute)!
        let nullDeviceStrategyEntryPoint = MemoryLayout<_SysInitVars>.offset(of: \.nullDeviceStrategyEntryPoint)!
        let nullDeviceInterruptEntryPoint = MemoryLayout<_SysInitVars>.offset(of: \.nullDeviceInterruptEntryPoint)!
        let nullDeviceName = MemoryLayout<_SysInitVars>.offset(of: \.nullDeviceName)!
        let spliceIndicator = MemoryLayout<_SysInitVars>.offset(of: \.spliceIndicator)!
        let DOSSizeInParagraphs = MemoryLayout<_SysInitVars>.offset(of: \.DOSSizeInParagraphs)!
        let DOSServiceRoutineEntry = MemoryLayout<_SysInitVars>.offset(of: \.DOSServiceRoutineEntry)!
        let IFSChain = MemoryLayout<_SysInitVars>.offset(of: \.IFSChain)!
        let buffer = MemoryLayout<_SysInitVars>.offset(of: \.buffer)!
        let lastDrive = MemoryLayout<_SysInitVars>.offset(of: \.lastDrive)!
        let bootDrive = MemoryLayout<_SysInitVars>.offset(of: \.bootDrive)!
        let machine386 = MemoryLayout<_SysInitVars>.offset(of: \.machine386)!
        let extendedMemorySize = MemoryLayout<_SysInitVars>.offset(of: \.extendedMemorySize)!
        let reserved1 = MemoryLayout<_SysInitVars>.offset(of: \.reserved1)!
    }
    private let ofs = Ofs()
}
