// DisplayParameterBlock.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import XTSwiftCPU8088

public class DisplayParameterBlock: MemorySpace {

    init(_ memory: Memory, _ segment: UInt16, _ offset: UInt16) {
        super.init(memory, segment, offset, MemoryLayout<_DPB>.size)
        assert(ofs.controlFlags == 0x04)
        assert(ofs.characterRows == 0x10)

        setByte(ofs.level, 0)
        setByte(ofs.reserved1, 0)
        setByte(ofs.lengthOfData, 14)
        setWord(ofs.controlFlags, 0) // intensity
        setByte(ofs.modeType, 1) // text
        setByte(ofs.reserved2, 0)
        setWord(ofs.colors, 0) // monochrome
        setWord(ofs.pixelColumns, 0)
        setWord(ofs.pixelRows, 0)
        setWord(ofs.characterColumns, 80)
        setWord(ofs.characterRows, 25)
    }

    // MARK: - Internal

    private struct Ofs {
        let level = MemoryLayout<_DPB>.offset(of: \.level)!
        let reserved1 = MemoryLayout<_DPB>.offset(of: \.reserved1)!
        let lengthOfData = MemoryLayout<_DPB>.offset(of: \.lengthOfData)!
        let controlFlags = MemoryLayout<_DPB>.offset(of: \.controlFlags)!
        let modeType = MemoryLayout<_DPB>.offset(of: \.modeType)!
        let reserved2 = MemoryLayout<_DPB>.offset(of: \.reserved2)!
        let colors = MemoryLayout<_DPB>.offset(of: \.colors)!
        let pixelColumns = MemoryLayout<_DPB>.offset(of: \.pixelColumns)!
        let pixelRows = MemoryLayout<_DPB>.offset(of: \.pixelRows)!
        let characterColumns = MemoryLayout<_DPB>.offset(of: \.characterColumns)!
        let characterRows = MemoryLayout<_DPB>.offset(of: \.characterRows)!
    }
    private let ofs = Ofs()
}
