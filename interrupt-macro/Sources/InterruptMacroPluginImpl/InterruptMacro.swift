// InterruptMacro.swift
// XT Copyright© 2026; Electric Bolt Limited.

import SwiftSyntax
import SwiftSyntaxMacros
import Foundation

/// If you are changing this Macro code in Xcode and want to confirm correct code generation, then:
/// • Product ‣ Clean Build Folder
/// • File ‣ Packages ‣ Reset Package Caches
/// Allow Xcode to rebuild the Macro, then expand macro by using:
/// • Editor ‣ Expand Macro

/// Based upon the following source definition:
///
/// ```
/// public class ConsoleIO {
///
///     @Interrupt(function = 0x09, description = "Write string to standard output")
///     func writeString(_ cpu: CPU, @ASCIZ(terminator: "$") @DS @DX _ s: String) {
///         print(s)
///     }
/// }
/// ```
///
/// The Macro will generate the following:
///
/// ```
/// @section("__DATA_CONST,__xtinterrupts")
/// @used
/// private static let $writeString: Interrupt = (
///     className: {
///         TaskContext.result?.value = "ConsoleIO"
///     },
///     create: {
///         TaskContext.result?.value = ConsoleIO()
///     },
///     execute: {
///         let cpu = TaskContext.cpu!
///         let trace = TaskContext.trace!
///         let s = cpu.memory.readStringZ(SegOfs(cpu.reg.DS, cpu.reg.DX), "$")
///         let instance = TaskContext.instance!.value as! ConsoleIO
///         trace.interrupt("INT 21 function 06 - Write string to standard output. s=\"\(s)\"")
///         instance.writeString(cpu, s)
///     },
///     description: {
///         TaskContext.result?.value = "Write string to standard output"
///     },
///     interrupt: 0x21,
///     function: 0x09,
///     subfunction: -1
/// )
/// ```

extension DeclGroupSyntax {

    /// The type declared or extended by this instance.

    var type: TypeSyntax {
        if let namedDecl = asProtocol((any NamedDeclSyntax).self) {
            return TypeSyntax(IdentifierTypeSyntax(name: namedDecl.name))
        } else if let extensionDecl = `as`(ExtensionDeclSyntax.self) {
            return extensionDecl.extendedType
        }
        fatalError("Unexpected DeclGroupSyntax type \(Swift.type(of: self)).")
    }
}

extension MacroExpansionContext {

  /// Get the type of the given lexical context.
  ///
  /// - Parameters:
  ///   - lexicalContext: The lexical context.
  ///
  /// - Returns: The type represented by `lexicalContext`, or `nil` if one could
  ///   not be derived (for example, because the lexical context inclues a
  ///   function, closure, or some other non-type scope.)
  ///
  /// If the lexical context includes functions, closures, or some other
  /// non-type scope, the value of this property is `nil`.

  func type(ofLexicalContext lexicalContext: some RandomAccessCollection<Syntax>) -> TypeSyntax? {
    var typeNames = [String]()
    for lexicalContext in lexicalContext.reversed() {
      guard let decl = lexicalContext.asProtocol((any DeclGroupSyntax).self) else {
        return nil
      }
      typeNames.append(decl.type.trimmedDescription)
    }
    if typeNames.isEmpty {
      return nil
    }

    return "\(raw: typeNames.joined(separator: "."))"
  }

  /// The type of the lexical context enclosing the given node.
  ///
  /// If the lexical context includes functions, closures, or some other
  /// non-type scope, the value of this property is `nil`.

  var typeOfLexicalContext: TypeSyntax? {
    type(ofLexicalContext: lexicalContext)
  }
}

public struct InterruptMacro: PeerMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw MacroError.notFunction
        }

        var className: String? = nil
        let typeName: TypeSyntax? = context.typeOfLexicalContext
        if let typeName = typeName {
            className = typeName.description
        }

        let funcName = funcDecl.name.text

        // Parse: `@Interrupt(function = 0x09, description = "Write string to standard output")`
        let attributes = funcDecl.attributes
        var interrupt: UInt8 = 0x21
        var function: UInt8? = nil
        var subfunction: UInt8? = nil
        var description = ""
        let attributeElement = attributes.first!
        if let attr = attributeElement.as(AttributeSyntax.self) {
            if let args = attr.arguments?.as(LabeledExprListSyntax.self) {
                for arg in args {
                    if arg.label?.text == "interrupt" {
                        if let intLit = arg.expression.as(IntegerLiteralExprSyntax.self) {
                            interrupt = toUInt8(intLit.literal.text)
                        }
                    } else if arg.label?.text == "function" {
                        if let intLit = arg.expression.as(IntegerLiteralExprSyntax.self) {
                            function = toUInt8(intLit.literal.text)
                        }
                    } else if arg.label?.text == "subfunction" {
                        if let intLit = arg.expression.as(IntegerLiteralExprSyntax.self) {
                            subfunction = toUInt8(intLit.literal.text)
                        }
                    } else if arg.label?.text == "description" {
                        if let strLit = arg.expression.as(StringLiteralExprSyntax.self) {
                            description = strLit.segments.compactMap {
                                guard case .stringSegment(let seg) = $0 else { return nil }
                                return seg.content.text
                            }.joined()
                        }
                    }
                }
            }
        }

        // Parse: `func writeString(_ cpu: CPU, @ASCIZ(terminator: "$") @DS @DX _ s: String) {`
        var parameterInfos: [ParameterInfo] = []

        for param in funcDecl.signature.parameterClause.parameters {
            // Prefer the internal name (secondName e.g. "cpu") over the external label (firstName e.g. "_")
            let paramName = param.secondName?.text ?? param.firstName.text
            let paramType = param.type.as(IdentifierTypeSyntax.self)!.name.text
            var wrappers: [String] = []
            var wrapperValues: [String] = []

            if !param.attributes.isEmpty {
                for attributeElement in param.attributes {
                    var wrapperName = ""
                    var wrapperValue = ""
                    if let attr = attributeElement.as(AttributeSyntax.self) {
                        wrapperName = attr.attributeName.trimmedDescription
                        if let args = attr.arguments?.as(LabeledExprListSyntax.self) {
                            for arg in args where arg.label?.text == "terminator" {
                                if let strLit = arg.expression.as(StringLiteralExprSyntax.self) {
                                    wrapperValue = strLit.segments.compactMap {
                                        guard case .stringSegment(let seg) = $0 else { return nil }
                                        return seg.content.text
                                    }.joined()
                                }
                            }
                        }
                    }
                    wrappers.append(wrapperName)
                    wrapperValues.append(wrapperValue)
                }
            }

            parameterInfos.append(ParameterInfo(name: paramName, type: paramType, wrappers: wrappers, wrapperValues: wrapperValues))
        }

        var buf = """
        @section("__DATA_CONST,__xtinterrupts")
        @used
        private static let $\(funcName): Interrupt = (
            className: {
                TaskContext.result?.value = \"\(className!)\"
            },
            create: {
                TaskContext.result?.value = \(className!)()
            },
            execute: {
                let cpu = TaskContext.cpu!
                let trace = TaskContext.trace!\n
        """

        var ifsBuf = ""
        var traceBuf = ""
        ifsBuf += "    interrupt: 0x\(String(format: "%02X", Int(interrupt))),\n"
        traceBuf += "INT \(String(format: "%02X", Int(interrupt)))"

        if function == nil {
            ifsBuf += "    function: -1,\n"
        } else {
            ifsBuf += "    function: 0x\(String(format: "%02X", Int(function!))),\n"
            traceBuf += " function \(String(format: "%02X", Int(function!)))"
        }

        if subfunction == nil {
            ifsBuf += "    subfunction: -1\n"
        } else {
            ifsBuf += "    subfunction: 0x\(String(format: "%02X", Int(subfunction!)))\n"
            traceBuf += "\(String(format: "%02X", Int(subfunction!)))"
        }

        traceBuf += " - \(description)."

        for i in 0..<parameterInfos.count {
            let parameterInfo = parameterInfos[i]

            switch parameterInfo.type {
                case "CPU":
                    break
                case "Trace":
                    break
                case "DirectoryTranslation":
                    buf += "        let directoryTranslation = TaskContext.directoryTranslation!\n"
                case "ExecutionContext":
                    buf += "        let context = TaskContext.context!\n"
                case "String":
                    let terminatorChar = parameterInfo.wrapperValues[0]
                    let seg = parameterInfo.wrappers[1]
                    let ofs = parameterInfo.wrappers[2]
                    buf += "        let \(parameterInfo.name) = cpu.memory.readStringZ(SegOfs(cpu.reg.\(seg), cpu.reg.\(ofs)), \"\(terminatorChar)\")"
                    traceBuf += " \(parameterInfo.name)=\\\"\\(\(parameterInfo.name))\\\""
                case "Character":
                    let reg = parameterInfo.wrappers[0]
                    buf += "        let \(parameterInfo.name) = Character(UnicodeScalar(cpu.reg.\(reg).getValue()))"
                    traceBuf += " \(parameterInfo.name)='\\(\(parameterInfo.name))'"
                case "SegOfs":
                    let seg = parameterInfo.wrappers[0]
                    let ofs = parameterInfo.wrappers[1]
                    buf += "        let \(parameterInfo.name) = SegOfs(cpu.reg.\(seg).getValue(), cpu.reg.\(ofs).getValue())"
                    traceBuf += " \(parameterInfo.name)=\\(\(parameterInfo.name).description)"
                case "Bool":
                    let reg = parameterInfo.wrappers[0]
                    buf += "        let \(parameterInfo.name) = cpu.reg.\(reg).getValue() != 0"
                    traceBuf += " \(parameterInfo.name)=\\(String(format: \"%02X\", \(parameterInfo.name)))"
                case "UInt8":
                    let reg = parameterInfo.wrappers[0]
                    buf += "        let \(parameterInfo.name) = cpu.reg.\(reg).getValue()"
                    traceBuf += " \(parameterInfo.name)=\\(String(format: \"%02X\", \(parameterInfo.name)))"
                case "UInt16":
                    let reg = parameterInfo.wrappers[0]
                    buf += "        let \(parameterInfo.name) = cpu.reg.\(reg).getValue()"
                    traceBuf += " \(parameterInfo.name)=\\(String(format: \"%04X\", \(parameterInfo.name)))"
                case "UInt32":
                    let hi = parameterInfo.wrappers[0]
                    let lo = parameterInfo.wrappers[1]
                    buf += "        let \(parameterInfo.name) = UInt32((cpu.reg.\(hi).getValue() << 16 & 0xFFFF)) | UInt32((cpu.reg.\(lo).getValue() & 0xFFFF))"
                    traceBuf += " \(parameterInfo.name)=\\(String(format: \"%08X\", \(parameterInfo.name)))"
                default:
                    throw MacroError.invalidType
            }
        }

        buf += """
                trace.interrupt("\(traceBuf)")
                let instance = TaskContext.instance!.value as! \(className!)
                instance.\(funcName)(
        """

        for i in 0..<parameterInfos.count {
            let parameterInfo = parameterInfos[i]
            switch parameterInfo.type {
                case "CPU":
                    buf += "cpu"
                case "Trace":
                    buf += "trace"
                case "DirectoryTranslation":
                    buf += "directoryTranslation"
                case "ExecutionContext":
                    buf += "context"
                default:
                    buf += "\(parameterInfo.name)"
            }
            if i < parameterInfos.count - 1 {
                buf += ", "
            }
        }
        buf += ")\n"

        buf += """
            },
            description: {
                TaskContext.result?.value = "\(description)"
            },\n
        """
        buf += ifsBuf
        buf += ")\n"

        return [
            """
            \(raw: buf)
            """,
        ]
    }
}

private func toUInt8(_ value: String) -> UInt8 {
    if (value.hasPrefix("0x")) {
        let value = value.dropFirst(2)
        return UInt8(value, radix: 16) ?? 0
    } else {
        return UInt8(value) ?? 0
    }
}

private enum MacroError: Error, CustomStringConvertible {
    case notFunction
    case invalidType

    var description: String {
        switch self {
            case .notFunction:
                return "Interrupt macro can only be attached to a function."
            case .invalidType:
                return "Parameter types must be CPU, Trace, DirectoryTranslation, ExecutionContext, String, Character, SegOfs, Bool, UInt8, UInt16 or UInt32."
        }
    }
}

private struct ParameterInfo: CustomStringConvertible {
    public let name: String
    public let type: String
    public let wrappers: [String]
    public let wrapperValues: [String]

    public init(name: String, type: String, wrappers: [String], wrapperValues: [String]) {
        self.name = name
        self.type = type
        self.wrappers = wrappers
        self.wrapperValues = wrapperValues
    }

    public var description: String {
        var buf = "name: \(name) type: \(type)"
        buf += " wrappers: (\(wrappers.joined(separator: ", ")))"
        buf += " values: (\(wrapperValues.joined(separator: ", ")))"
        return buf
    }
}
