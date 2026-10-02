// FileIO.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation
import InterruptMacroPlugin
import XTSwiftCPU8088

public class FileIO {

    public init() {
        var _stderr = false
        if let exitOnStdIn = ProcessInfo.processInfo.environment["XT_COMBINE_STDOUT_STDERR"] {
            if exitOnStdIn == "1" {
                _stderr = true
            }
        }

        // STDIN - keyboard.
        fileHandleMap[fileHandleCount] = CONFile(accessMode: .readOnly, sharingMode: .denyWrite, inheritenceFlag: true, stdout: true)
        fileHandleCount += 1

        // STDOUT - screen.
        fileHandleMap[fileHandleCount] = CONFile(accessMode: .writeOnly, sharingMode: .denyRead, inheritenceFlag: true, stdout: true)
        fileHandleCount += 1

        // STDERR - screen.
        fileHandleMap[fileHandleCount] = CONFile(accessMode: .writeOnly, sharingMode: .denyNone, inheritenceFlag: true, stdout: _stderr)
        fileHandleCount += 1

        // STDAUX - first serial port.
        fileHandleMap[fileHandleCount] = NULFile()
        fileHandleCount += 1

        // STDPRN - first printer port.
        fileHandleMap[fileHandleCount] = NULFile()
        fileHandleCount += 1
    }

    public static func getDirectoryFromPath(_ path: String) -> String {
        if let range = path.range(of: "\\", options: .backwards) {
            return String(path[..<range.lowerBound])
        }
        return ""
    }

    public static func getFilenameFromPath(_ path: String) -> String {
        if let range = path.range(of: "\\", options: .backwards) {
            return String(path[range.upperBound...])
        }
        return path
    }

    @Interrupt(function: 0x19, description: "Get current default drive")
    func getCurrentDefaultDrive(_ cpu: CPU) {
        cpu.reg.AL.setValue(0x02) // C:
    }

    @Interrupt(function: 0x1A, description: "Set disk transfer area address")
    func setDiskTransferArea(_ cpu: CPU, @DS @DX _ address: SegOfs) {
        self.diskTransferArea = address
    }

    @Interrupt(function: 0x2F, description: "Get disk transfer area address")
    func getDiskTransferArea(_ cpu: CPU) {
        cpu.reg.ES.setValue(diskTransferArea.getSegment())
        cpu.reg.BX.setValue(diskTransferArea.getOffset())
    }

    @Interrupt(function: 0x3C, description: "Create or truncate file")
    func createFile(_ cpu: CPU, _ trace: Trace, _ directoryTranslation: DirectoryTranslation,
                    @CX _ fileAttributes: UInt16, @ASCIZ(terminator: "\0") @DS @DX _ filename: String) {
        // TODO: should use fileAttributes specified.
        let filename = directoryTranslation.emulatedPathToHostPath(filename.uppercased())
        trace.interrupt("Host filename \(filename)")
        let baseFile = DiskFile(filename, .readWrite, .compatibilityMode, false)
        if !baseFile.create() {
            trace.interrupt("Failed")
            setErrorResult(cpu, trace, .pathNotFound)
            return
        }

        trace.interrupt("Returning filehandle \(fileHandleCount)")
        baseFile.setFileHandle(fileHandleCount)
        fileHandleMap[fileHandleCount] = baseFile
        fileHandleCount += 1
        cpu.reg.flags.setCarry(false)
        cpu.reg.AX.setValue(baseFile.getFileHandle())
    }

    @Interrupt(function: 0x3D, description: "Open existing file")
    func openFile(_ cpu: CPU, _ trace: Trace, _ directoryTranslation: DirectoryTranslation,
                  @ASCIZ(terminator: "\0") @DS @DX _ filename: String, @AL _ accessSharingMode: UInt8,
                  @CL _ attributeMask: UInt8) {
        var filename = filename

        let _accessMode = accessSharingMode & 0x07
        guard let accessMode = AccessMode(rawValue: _accessMode) else {
            trace.interrupt("Invalid access mode \(_accessMode)")
            setErrorResult(cpu, trace, .accessCodeInvalid)
            return
        }

        let _sharingMode = (accessSharingMode >> 4) & 0x07
        guard let sharingMode = SharingMode(rawValue: _sharingMode) else {
            trace.interrupt("Invalid sharing mode \(_sharingMode)")
            setErrorResult(cpu, trace, .accessCodeInvalid)
            return
        }

        let inheritenceFlag = (accessSharingMode & 0x80) == 0x80

        if filename == "NUL" {
            trace.interrupt("Returning filehandle \(fileHandleCount)")

            let baseFile = NULFile()
            baseFile.setFileHandle(fileHandleCount)
            fileHandleMap[fileHandleCount] = baseFile
            fileHandleCount += 1

            cpu.reg.flags.setCarry(false)
            cpu.reg.AX.setValue(baseFile.getFileHandle())
        } else if filename == "EMMXXXX0" {
            trace.interrupt("EMM memory not implemented")
            setErrorResult(cpu, trace, .fileNotFound)
        } else {
            filename = directoryTranslation.emulatedPathToHostPath(filename.uppercased())
            trace.interrupt("Host filename \(filename)")
            let baseFile = DiskFile(filename, accessMode, sharingMode, inheritenceFlag)
            if !baseFile.open() {
                trace.interrupt("Failed")
                setErrorResult(cpu, trace, .fileNotFound)
            } else {
                trace.interrupt("Returning filehandle \(fileHandleCount)")

                baseFile.setFileHandle(fileHandleCount)
                fileHandleMap[fileHandleCount] = baseFile
                fileHandleCount += 1

                cpu.reg.flags.setCarry(false)
                cpu.reg.AX.setValue(baseFile.getFileHandle())
            }
        }
    }

    @Interrupt(function: 0x3E, description: "Close file")
    func closeFile(_ cpu: CPU, _ trace: Trace, @BX _ fileHandle: UInt16) {
        if let baseFile = getFileHandleOrSetErrorResult(cpu, trace, fileHandle) {
            if baseFile.close() {
                fileHandleMap.removeValue(forKey: fileHandle)
            }
            cpu.reg.flags.setCarry(false)
        }
    }

    @Interrupt(function: 0x3F, description: "Read from file or device")
    func readFile(_ cpu: CPU, _ trace: Trace, @BX _ fileHandle: UInt16,
                  @CX _ numberOfBytesToRead: UInt16, @DS @DX _ address: SegOfs) {
        if let baseFile = getFileHandleOrSetErrorResult(cpu, trace, fileHandle) {
            let buf = baseFile.read(Int(numberOfBytesToRead))
            cpu.reg.flags.setCarry(false)
            if buf == nil {
                cpu.reg.AX.setValue(0)
            } else {
                cpu.memory.writeBuf(address, buf!)
                cpu.reg.AX.setValue(UInt16(buf!.count))
            }
        }
    }

    @Interrupt(function: 0x40, description: "Write to file or device")
    func writeFile(_ cpu: CPU, _ trace: Trace, @BX _ fileHandle: UInt16,
                   @CX _ numberOfBytesToWrite: UInt16, @DS @DX _ address: SegOfs) {
        if let baseFile = getFileHandleOrSetErrorResult(cpu, trace, fileHandle) {
            let buf = cpu.memory.readBuf(address, numberOfBytesToWrite)
            baseFile.write(buf)
            cpu.reg.flags.setCarry(false)
            cpu.reg.AX.setValue(UInt16(buf.count))
        }
    }

    @Interrupt(function: 0x41, description: "Delete file")
    func deleteFile(_ cpu: CPU, _ trace: Trace, @BX _ fileHandle: UInt16) {
        if let baseFile = getFileHandleOrSetErrorResult(cpu, trace, fileHandle) {
            if !baseFile.delete() {
                setErrorResult(cpu, trace, .fileNotFound)
                return
            }
            cpu.reg.flags.setCarry(false)
            cpu.reg.AL.setValue(0x03) // Documentation says "appears to be drive of deleted file".
        }
    }

    @Interrupt(function: 0x42, description: "Set current file position")
    func seekFile(_ cpu: CPU, _ trace: Trace, @BX _ fileHandle: UInt16, @CX @DX _ offset: UInt32, @AL _ origin: UInt8) {
        if let baseFile = getFileHandleOrSetErrorResult(cpu, trace, fileHandle) {
            var offset = Int32(bitPattern: offset)
            switch origin {
                case 0x00:
                    trace.interrupt("Seeking to beginning")
                case 0x01:
                    trace.interrupt("Seeking from current")
                    offset &+= Int32(baseFile.currentPos())
                case 0x02:
                    trace.interrupt("Seeking from end")
                    offset &+= Int32(baseFile.size())
                default:
                    trace.interrupt("Invalid seek mode \(origin)")
                    setErrorResult(cpu, trace, .functionNumberInvalid)
                    return
            }
            baseFile.seek(offset)
            cpu.reg.flags.setCarry(false)
            let uOffset = UInt32(bitPattern: offset)
            cpu.reg.DX.setValue(UInt16((uOffset >> 16) & 0xFFFF))
            cpu.reg.AX.setValue(UInt16(uOffset & 0xFFFF))
        }
    }

    @Interrupt(function: 0x43, subfunction: 0x00, description: "Get file attributes")
    func getFileAttributes(_ cpu: CPU, _ trace: Trace, _ directoryTranslation: DirectoryTranslation,
                           @ASCIZ(terminator: "\0") @DS @DX _ filename: String) {
        let filename = directoryTranslation.emulatedPathToHostPath(filename.uppercased())
        trace.interrupt("Host filename \(filename)")
        do {
            var result: UInt16 = 0
            let fileAttrs: [FileAttributeKey:Any] = try FileManager.default.attributesOfItem(atPath: filename)
            let permissions = (fileAttrs[.posixPermissions] as? Int) ?? 0
            if (permissions & 0o200) == 0 { // no OWNER_WRITE
                result |= UInt16(FileAttribute.readOnly.rawValue)
            }
            if fileAttrs[.type] as? FileAttributeType != .typeDirectory {
                result |= UInt16(FileAttribute.directory.rawValue)
            }
            cpu.reg.flags.setCarry(false)
            cpu.reg.AX.setValue(result)
        } catch {
            setErrorResult(cpu, trace, .fileNotFound)
        }
    }

    @Interrupt(function: 0x44, subfunction: 0x00, description: "IOCTL Get device information")
    func getDeviceInformation(_ cpu: CPU, _ trace: Trace, @BX _ fileHandle: UInt16) {
        if let baseFile = getFileHandleOrSetErrorResult(cpu, trace, fileHandle) {
            cpu.reg.flags.setCarry(false)
            cpu.reg.DX.setValue(baseFile.getDeviceInformationWord())
        }
    }

    @Interrupt(function: 0x44, subfunction: 0x01, description: "IOCTL Set device information")
    func setDeviceInformation(_ cpu: CPU, _ trace: Trace, @BX _ fileHandle: UInt16,
                              @DX _ newDeviceInformationWord: UInt16) {
        if getFileHandleOrSetErrorResult(cpu, trace, fileHandle) != nil {
            cpu.reg.flags.setCarry(false)
        }
    }

    @Interrupt(function: 0x44, subfunction: 0x07, description: "IOCTL Get input/output status")
    func getOutputStatus(_ cpu: CPU, _ trace: Trace, @BX _ fileHandle: UInt16) {
        if getFileHandleOrSetErrorResult(cpu, trace, fileHandle) != nil {
            cpu.reg.flags.setCarry(false)
            cpu.reg.AL.setValue(0xFF) // Ready.
        }
    }

    @Interrupt(function: 0x44, subfunction: 0x0C, description: "IOCTL Generic character device request")
    func genericCharacterDeviceRequest(_ cpu: CPU, _ trace: Trace, @BX _ fileHandle: UInt16, @CH _ category: UInt8,
                                       @CL _ function: UInt8, @DS @DX _ parameterBlock: SegOfs) {
        if getFileHandleOrSetErrorResult(cpu, trace, fileHandle) != nil {
            if category != 0x03 {
                // Not CON:
                print("Unsupported category \(category)")
                exit(255);
            }
            if function != 0x7F {
                // Not GetDisplayInformation
                trace.log("Unsupported function \(function)")
                exit(255);
            }
            let _ = DisplayParameterBlock(cpu.memory, parameterBlock.getSegment(), parameterBlock.getOffset())
            cpu.reg.flags.setCarry(false)
        }
    }

    @Interrupt(function: 0x4E, description: "Find first matching file")
    func findFirstMatchingFile(_ cpu: CPU, _ trace: Trace, _ directoryTranslation: DirectoryTranslation,
                               @AL _ appendFlag: UInt8, @ASCIZ(terminator: "\0") @DS @DX _ path: String,
                               @CX _ attributeMask: UInt16) {
        var directory = FileIO.getDirectoryFromPath(path)
        let filename = FileIO.getFilenameFromPath(path)

        directory = directoryTranslation.emulatedPathToHostPath(directory.uppercased())
        trace.interrupt("Host path \(directory) filename \(filename)")

        let matcher = WildcardFileMatcher(filename.uppercased())
        do {
            var files: [String] = try FileManager.default.contentsOfDirectory(atPath: directory)
            files = files.filter { matcher.matches($0) }

            guard !files.isEmpty else {
                setErrorResult(cpu, trace, .fileNotFound)
                return
            }
            let filename: String = files.first!
            let fileAttrs: [FileAttributeKey:Any] = try FileManager.default.attributesOfItem(atPath: filename)

            let dta = DiskTransferArea(cpu.memory, UInt16(0x0090), UInt16(0x0080))
            let fileDateTime = FileDateTime(fileAttrs[.modificationDate] as! Date)
            dta.writeFileDate(fileDateTime.toDOSDate())
            dta.writeFileTime(fileDateTime.toDOSTime())
            dta.writeFileSize(Int(fileAttrs[.size] as! Int))
            dta.writeFilename(filename)

            let data = FindFileData(internalId: findFileCount, files: files, fileIndex: 0, diskTransferArea: dta)
            findFileMap[findFileCount] = data
            dta.setInternalId(findFileCount); findFileCount += 1
            cpu.reg.flags.setCarry(false)
        } catch {
            setErrorResult(cpu, trace, .fileNotFound)
            return
        }
    }

    @Interrupt(function: 0x56, description: "Rename file")
    func renameFile(_ cpu: CPU, _ trace: Trace, _ directoryTranslation: DirectoryTranslation,
                    @ASCIZ(terminator: "\0") @DS @DX _ source: String, @ASCIZ(terminator: "\0") @ES @DI _ dest: String) {
        let sourceFile: String = directoryTranslation.emulatedPathToHostPath(source.uppercased())
        let destFile: String = directoryTranslation.emulatedPathToHostPath(dest.uppercased())

        // TODO: test in real DOS what the actual error codes are based upon the scenarios of files/paths wrong.
        if !FileManager.default.fileExists(atPath: sourceFile) {
            setErrorResult(cpu, trace, .fileNotFound)
            return
        } else if FileManager.default.fileExists(atPath: destFile) {
            setErrorResult(cpu, trace, .pathNotFound)
            return
        }

        do {
            try FileManager.default.moveItem(atPath: sourceFile, toPath: destFile)
            cpu.reg.flags.setCarry(false)
        } catch {
            setErrorResult(cpu, trace, .pathNotFound)
        }
    }

    @Interrupt(function: 0x57, subfunction: 0x00, description: "Get file's date and time")
    func getFileDateTime(_ cpu: CPU, _ trace: Trace, @BX _ fileHandle: UInt16) {
        if let baseFile = getFileHandleOrSetErrorResult(cpu, trace, fileHandle) {
            let fileDateTime = baseFile.getDateTime()
            if fileDateTime == nil {
                setErrorResult(cpu, trace, .invalidHandle)
                return
            }

            cpu.reg.flags.setCarry(false)
            cpu.reg.CX.setValue(fileDateTime!.toDOSTime())
            cpu.reg.DX.setValue(fileDateTime!.toDOSDate())
        }
    }

    // MARK: - Internal

    private var fileHandleMap = [UInt16: BaseFile]()
    private var findFileMap = [UInt16: FindFileData]()
    private var fileHandleCount: UInt16 = 0
    private var diskTransferArea = SegOfs(UInt16(0x0090), UInt16(0x0080))
    private var findFileCount: UInt16 = 0

    /// Retrieves the BaseFile that is associated with the filehandle specified. If the filehandle is invalid, AX will be set to 06h
    /// (invalid file handle), the carry flag set and the function will return null. Otherwise the BaseFile is returned.

    private func getFileHandleOrSetErrorResult(_ cpu: CPU, _ trace: Trace, _ fileHandle: UInt16) -> BaseFile? {
        guard let baseFile = fileHandleMap[fileHandle] else {
            trace.interrupt("Invalid filehandle \(fileHandle)")
            setErrorResult(cpu, trace, .invalidHandle)
            return nil
        }
        return baseFile
    }

    /// Sets the AX register to the specified error code and sets the carry flag.

    private func setErrorResult(_ cpu: CPU, _ trace: Trace, _ errorCode: ErrorCode) {
        trace.interrupt("Returning error \(errorCode.rawValue)")
        cpu.reg.flags.setCarry(true)
        cpu.reg.AX.setValue(errorCode.rawValue)
    }
}

