// Interrupts.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088

/// Invokes a method that handles the interrupt ‣ function ‣ subfunction.
///
/// ```
/// @Interrupt(function: 0x09, description: "Write string to standard output")
/// func writeString(_ cpu: CPU, @ASCIZ(terminator: "$") @DS @DX _ s: String) {
///    print(s, terminator: "")
///    cpu.reg.AL.setValue(("$" as Character).asciiValue!);
/// }
/// ```
///
/// @Iinterrupt contains the following parameters:
/// - `interrupt` - if not specified, defaults to the value 0x21.
/// - `function` - an optional function number that would be in the AH register.
/// - `subfunction` - an optional subfunction number that would be in the AL register.
/// - `description` - for a developer.
///
/// The method declaration must have parameters declared in the following order:
/// - `CPU` - mandatory, as every interrupt handler method requires access to the CPU, registers and memory.
/// - `Trace` - optional, used to output tracing info to the trace file (if enabled).
/// - `DirectoryTranslation` - optional, used to convert emulated directory to host directories and vice versa.
/// - `register` parameters - optional, if the interrupt function uses registers as request parameters.
///
/// Register parameters must be one of the following types:
/// - `Bool` - Prefixed by @AL, @BL, @CL, @DL, @AH, @BH, @CH or @DH . 0 != is true, 0 is false.
/// - `UInt8` - Prefixed by @AL, @BL, @CL, @DL, @AH, @BH, @CH or @DH.
/// - `UInt16` - Prefixed by @AX, @BX, @CX, @DX, @SI or @DI.
/// - `UInt32` - Prefixed with a pair of @AX, @BX, @CX, @DX, @SI or @DI. (High-order word, Low-order word).
/// - `SegOfs` - Prefixed by @DS or @ES; and @AX, @BX, @CX, @DX, @SI or @DI.
/// - `String` - Prefixed by ASCIZ(terminator: ), then @DS or @ES; and @AX, @BX, @CX, @DX, @SI or @DI.
/// - `Character` - Prefixed by @AL, @BL, @CL, @DL, @AH, @BH, @CH or @DH.
///
/// Methods can always access `CPU` registers directly if the above list of property types is not enough.

public class Interrupts {

    public init() {
        load()
    }

    public func execute(_ cpu: CPU, _ interrupt: UInt8, _ trace: Trace, _ directoryTranslation: DirectoryTranslation,
                        _ context: ExecutionContext) {
        // Check for interrupt match.
        let key = String(format: "%02X", interrupt)
        var impl: InterruptImpl! = implMap[key]
        if impl == nil {
            // Check for interrupt + AH match.
            let key = String(format: "%02X %02X", interrupt, cpu.reg.AH.getValue())
            impl = implMap[key]
            if impl == nil {
                // Check for interrupt + AH + AL match.
                let key = String(format: "%02X %02X %02X", interrupt, cpu.reg.AH.getValue(), cpu.reg.AL.getValue())
                impl = implMap[key]
                if impl == nil {
                    trace.log(String(format: "Unhandled interrupt %02X", interrupt));
                    trace.log(cpu.reg.description);
                    print(String(format: "Unhandled interrupt %02X", interrupt), to: &stderr);
                    print(cpu.reg.description, to: &stderr);
                    exit(255)
                }
            }
        }

        let result = Box<Any>()
        result.value = impl.instance
        TaskContext.$instance.withValue(result) {
            TaskContext.$cpu.withValue(cpu) {
                TaskContext.$trace.withValue(trace) {
                    TaskContext.$directoryTranslation.withValue(directoryTranslation) {
                        TaskContext.$context.withValue(context) {
                            impl.execute()
                        }
                    }
                }
            }
        }
    }

    /// Invoked by main to print out the current list of implemented interrupt handling functions.

    public func printInterrupts(_ markdown: Bool = false) {
        for impl in implMap.values.sorted(by: { $0.description < $1.description }) {
            if markdown {
                print("- **\(impl.description)** - \(impl.developerDescription)")
            } else {
                print("\(impl.description) - \(impl.developerDescription)")
            }
        }
    }

    // MARK: - Internal

    private var implMap = [String:InterruptImpl]()

    /// Dynamically enumerates and loads all functions declared with @Interrupt linked into the binary.

    private func load() {
        var instanceMap = [String:Any]()

        getMachOSections().forEach { section in
            let address = UnsafeRawPointer(bitPattern: UInt(section.address))
            let interruptSize = MemoryLayout<Interrupt>.size // 38
            let interruptStride = MemoryLayout<Interrupt>.stride // 40

            // The size of each Interrupt tuple is 38 bytes. The stride is 40 bytes (integral of 8) which means 2 bytes
            // padding. There is no padding applied at the end of the section.
            var sectionSize = Int(section.size)
            if sectionSize > 0 {
                if interruptSize < interruptStride {
                    let stridePadding = interruptStride - interruptSize // 40-38=2
                    sectionSize += stridePadding
                }
            }

            let buffer = UnsafeRawBufferPointer(start: address, count: sectionSize)
            buffer.withMemoryRebound(to: Interrupt.self) { interrupts in
                for interrupt in interrupts {
                    let className = getClassName(from: interrupt)
                    let developerDescription = getDescription(from: interrupt)

                    // Create new instance of this class if not already created.
                    var instance = instanceMap[className]
                    if instance == nil {
                        instance = createInstance(from: interrupt)
                        instanceMap[className] = instance
                    }

                    var key = String(format: "%02X", interrupt.interrupt)
                    var description = "INT \(String(format: "%02X", interrupt.interrupt))"

                    if interrupt.function != -1 {
                        key += String(format: " %02X", interrupt.function)
                        description += " function \(String(format: "%02X", interrupt.function))"

                        if interrupt.subfunction != -1 {
                            key += String(format: " %02X", interrupt.subfunction)
                            description += String(format: "%02X", interrupt.subfunction)
                        }
                    }

                    implMap[key] = InterruptImpl(key,
                        interrupt.interrupt,
                        interrupt.function == -1 ? nil : UInt8(interrupt.function),
                        interrupt.subfunction == -1 ? nil : UInt8(interrupt.subfunction),
                        description,
                        developerDescription,
                        instance,
                        className,
                        interrupt.execute)
                }
            }
        }
    }
}

fileprivate struct InterruptImpl {
    let key: String                  // "20" (interrupt) or "21 02" (interrupt, function) or "21 33 01" (interrupt, function, subfunction).
    let interrupt: UInt8
    let function: UInt8?             // nil if no function.
    let subfunction: UInt8?          // nil if no subfunction.
    let description: String          // "INT 21 function 02".
    let developerDescription: String // "Write character to standard output".
    let instance: Any?               // Instance shared across all instances with identical className.
    let className: String            // Name of class "ConsoleIO".
    let execute: VoidFunction

    init(_ key: String, _ interrupt: UInt8, _ function: UInt8?, _ subfunction: UInt8?,
         _ description: String, _ developerDescription: String, _ instance: Any?, _ className: String,
         _ execute: VoidFunction) {
        self.key = key
        self.interrupt = interrupt
        self.function = function
        self.subfunction = subfunction
        self.description = description
        self.developerDescription = developerDescription
        self.instance = instance
        self.className = className
        self.execute = execute
    }
}
