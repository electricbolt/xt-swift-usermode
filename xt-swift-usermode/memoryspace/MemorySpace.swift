// MemorySpace.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088

/// Base class for all areas of memory. To view memory spaces, trigger a dump by using the `-ti trace.txt` command line parameter when running XT.

open class MemorySpace {

    /// Segment that this memory area starts at.
    public let segment: UInt16

    /// Offset within segment that this memory area starts at. By default is 0.
    public let offset: UInt16

    /// Memory object itself that we operate upon.
    public let memory: Memory

    /// Size (in bytes) of allocated memory area.
    public let size: Int

    /// Mirror object used for reflection of variable offsets in invalidMemoryAccess method.
    public let mirror: Mirror?

    public init(_ memory: Memory, _ paragraph: ParagraphAlloc, _ size: Int, _ mirror: Mirror? = nil) {
        self.memory = memory
        self.segment = UInt16(try! paragraph.alloc(algorithm: .firstFit, sizeInBytes: size))
        self.offset = 0
        self.size = size
        self.mirror = mirror
    }

    public init(_ memory: Memory, _ segment: UInt16, _ offset: UInt16, _ allocationSize: Int, _ mirror: Mirror? = nil) {
        self.memory = memory
        self.segment = segment
        self.offset = offset
        self.size = allocationSize
        self.mirror = mirror
    }

    /// Removes all permissions from this memory space.
    ///
    /// It is useful during development to remove all permissions to see what memory location a program is accessing. Any attempted memory read, write or
    /// execute will cause the `invalidMemoryAccess` method to be called. Once you have coded up the correct handling of that particular memory
    /// location, you can `allowPermission`, and the program should function correctly. See `BIOSDataArea.dailyTimerCounter` for an example.

    public func removePermission() {
        memory.removePermission(SegOfs(segment, 0).toLinearAddress(), size, Memory.PERMISSION_EXECUTE |
                                Memory.PERMISSION_READ | Memory.PERMISSION_WRITE)
    }

    /// Adds memory read, write and execute permissions to the offset..offset+size in the memory space.

    public func allowPermission(_ offset: Int, _ size: Int) {
        memory.applyPermission(SegOfs(segment, UInt16(offset)).toLinearAddress(), size, Memory.PERMISSION_EXECUTE |
                               Memory.PERMISSION_READ | Memory.PERMISSION_WRITE)
    }

    /// The identation level of the name of the memory space output by the `dump` method.
    ///
    /// Only the `MCB` and `PSP` are indented. All other memory spaces use the default 0.

    open func dumpIndent() -> Int {
        return 0
    }

    /// Called by `ExecutionContext` when tracing is enabled and running a program.

    public func dump() {
        let startAddr = SegOfs(segment, 0)
        let nameStr = name().padding(toLength: 22 - dumpIndent(), withPad: " ", startingAt: 0)
        var endAddr: SegOfs
        if size > 4096 {
            let endLinear = startAddr.toLinearAddress() + size - 1
            endAddr = SegOfs(UInt16(endLinear >> 4), UInt16(endLinear & 0xF))
        } else {
            endAddr = SegOfs(segment, UInt16(size - 1))
        }
        let startStr = startAddr.description.padding(toLength: 25, withPad: " ", startingAt: 0)
        let endStr = endAddr.description.padding(toLength: 25, withPad: " ", startingAt: 0)
        let indentStr = "".padding(toLength: dumpIndent(), withPad: " ", startingAt: 0)
        print("\(indentStr)\(nameStr) \(startStr) - \(endStr) size \(size) bytes")
    }

    /// Calculates if the `address` specified is within this memory space.

    public func contains(_ address: SegOfs) -> Bool {
        let start = SegOfs(segment, 0).toLinearAddress()
        let end = SegOfs(segment, UInt16(size - 1)).toLinearAddress()
        return address.toLinearAddress() >= start && address.toLinearAddress() <= end
    }

    /// Prints "Invalid memory access" with pertinent details of the memory location. Terminates the program.

    open func invalidMemoryAccess(_ cpu: CPU, _ trace: Trace, _ memoryAddress: SegOfs, _ permissionMask: UInt8, _ value: UInt8) {
        // If mirror is specified, then calculate the variable name that XT has faulted on. This makes development and
        // debugging of programs easier. e.g. faulting at location 0040:0002 would output "com2Port" (from BIOSDataArea)
        var field = ""
        if let mirror = mirror {
            for child in mirror.children.reversed() {
                let offset = child.value as! Int
                if memoryAddress.getOffset() >= offset {
                    field = "(\(child.label!)) "
                    break
                }
            }
        }

        let message = "Invalid memory access in \(name()) \(field)\(cpu.memory.fromBitmask(permissionMask)) - \(memoryAddress) - \(String(format: "%02X", value))"
        trace.log(message)
        trace.log(cpu.reg.description)
        print(message, to: &stderr)
        print(cpu.reg.description + "\n", to: &stderr)
        cpu.memory.dump(memoryAddress)
        exit(255)
    }

    /// The name of the instantiated class. e.g. `DOSVariables`

    internal func name() -> String {
        return String(describing: type(of: self))
    }

    /// Reads an 8-bit byte from memory at the specified `segment:offset + ofs`.
    ///
    /// Invokes `invalidMemoryAccess` if the memory address is not readable (`Memory.PERMISSION_READ`).

    internal func readByte(_ ofs: Int) -> UInt8 {
        return memory.readByte(SegOfs(segment, UInt16(Int(offset) &+ ofs)))
    }

    /// Reads an 16-bit word from memory at the specified `segment:offset + ofs`.
    ///
    /// Invokes `invalidMemoryAccess` if the memory address is not readable (`Memory.PERMISSION_READ`).

    internal func readWord(_ ofs: Int) -> UInt16 {
        return memory.readWord(SegOfs(segment, UInt16(Int(offset) &+ ofs)))
    }

    /// Writes an 8-bit byte to memory at the specified `segment:offset + ofs`.

    internal func setByte(_ ofs: Int, _ value: UInt8) {
        memory.setByte(SegOfs(segment, UInt16(Int(offset) &+ ofs)), value)
    }

    /// Writes an 16-bit word to memory at the specified `segment:offset + ofs`.

    internal func setWord(_ ofs: Int, _ value: UInt16) {
        memory.setWord(SegOfs(segment, UInt16(Int(offset) &+ ofs)), value)
    }

    /// Writes an 32-bit double word to memory at the specified `segment:offset + ofs`.

    internal func setDoubleWord(_ ofs: Int, _ value: UInt32) {
        memory.setDoubleWord(SegOfs(segment, UInt16(Int(offset) &+ ofs)), value)
    }
}
