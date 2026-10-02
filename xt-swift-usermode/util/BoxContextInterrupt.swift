// BoxContextInterrupt.swift
// XT Copyright © 2026; Electric Bolt Limited.

import XTSwiftCPU8088

/// A reference wrapper around any type.

class Box<T> {
    var value: T? = nil
}

/// Allows for passing parameters and results  the className, create, description and execute closures in the tuples

enum TaskContext {
    @TaskLocal static var cpu: CPU? = nil
    @TaskLocal static var trace: Trace? = nil
    @TaskLocal static var directoryTranslation: DirectoryTranslation? = nil
    @TaskLocal static var context: ExecutionContext? = nil
    @TaskLocal static var instance: Box<Any>? = nil
    @TaskLocal static var result: Box<Any>? = nil
}

typealias VoidFunction = @convention(c) () -> Void

/// Tuple that is used by the @Interrupt macro. The tuple has a limited range of constant literals when added to a MachO @section:
/// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0492-section-control.md

typealias Interrupt = (
  className: VoidFunction,
  create: VoidFunction,
  execute: VoidFunction,
  description: VoidFunction,
  interrupt: UInt8,
  function: Int16,
  subfunction: Int16
)

/// Literal strings are not allowed in MachO @section, we must call the className() closure to return the class name. Closure must be @convention(c) which
/// disallows Swift classes to be returned as a result. We use a @TaskLocal to return the result instead.
///
/// - Returns the name of the class containing the Interrupt specified.

func getClassName(from interrupt: Interrupt) -> String {
    let result = Box<Any>()
    TaskContext.$result.withValue(result) {
        interrupt.className()
    }
    return result.value as! String
}

/// Creates an instance of the class containing the Interrupt specified.
///
/// - Returns new instance of the class containing the Interrupt specified.

func createInstance(from interrupt: Interrupt) -> Any {
    let result = Box<Any>()
    TaskContext.$result.withValue(result) {
        interrupt.create()
    }
    return result.value!
}

/// Gets the developer description of the Interrupt specified.
///
/// - Returns description string.

func getDescription(from interrupt: Interrupt) -> String {
    let result = Box<Any>()
    TaskContext.$result.withValue(result) {
        interrupt.description()
    }
    return result.value as! String
}
