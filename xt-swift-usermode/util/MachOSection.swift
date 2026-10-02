// MachOSection.swift
// XT Copyright © 2026; Electric Bolt Limited.

import MachO

/// Returns the address and size of all the `__DATA_CONST,__xtinterrupts` MachO segments in binary.
/// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0492-section-control.md

func getMachOSections() -> [MachOSectionInfo] {
    var results: [MachOSectionInfo] = []
    let imageCount = _dyld_image_count()
    for imageIndex in 0..<imageCount {
        guard let headerPtr = _dyld_get_image_header(imageIndex), let imageNamePtr = _dyld_get_image_name(imageIndex) else {
            continue
        }
        guard headerPtr.pointee.magic == MH_MAGIC_64 || headerPtr.pointee.magic == MH_CIGAM_64 else {
            continue
        }
        guard 0 == headerPtr.pointee.flags & MH_DYLIB_IN_CACHE else {
            continue
        }
        let slide = Int64(_dyld_get_image_vmaddr_slide(imageIndex))

        let imageName = String(cString: imageNamePtr)
        let machHeader = UnsafeRawPointer(headerPtr).assumingMemoryBound(to: mach_header_64.self)
        var commandPtr = UnsafeRawPointer(machHeader).advanced(by: MemoryLayout<mach_header_64>.size)

        for _ in 0..<machHeader.pointee.ncmds {
            let loadCmd = commandPtr.assumingMemoryBound(to: load_command.self)
            if loadCmd.pointee.cmd == LC_SEGMENT_64 {
                let segment = commandPtr.assumingMemoryBound(to: segment_command_64.self)

                let segname = withUnsafePointer(to: segment.pointee.segname) { ptr -> String in
                    let raw = UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self)
                    return String(cString: raw)
                }

                let sectionPtr = UnsafeRawPointer(segment).advanced(by: MemoryLayout<segment_command_64>.size)
                    .assumingMemoryBound(to: section_64.self)

                for i in 0..<Int(segment.pointee.nsects) {
                    let section = sectionPtr.advanced(by: i).pointee

                    let sectname = withUnsafePointer(to: section.sectname) {
                        ptr -> String in
                        let raw = UnsafeRawPointer(ptr)
                            .assumingMemoryBound(to: CChar.self)
                        return String(cString: raw)
                    }

                    if segname == "__DATA_CONST" && sectname == "__xtinterrupts" {
                        results.append(MachOSectionInfo(imageName: imageName, segmentName: segname,
                                                        sectionName: sectname,
                                                        address: section.addr &+ UInt64(bitPattern: slide),
                                                        size: section.size))
                    }
                }
            }
            commandPtr = commandPtr.advanced(by: Int(loadCmd.pointee.cmdsize))
        }
    }
    return results
}

struct MachOSectionInfo {
    let imageName: String
    let segmentName: String
    let sectionName: String
    let address: UInt64
    let size: UInt64
}
