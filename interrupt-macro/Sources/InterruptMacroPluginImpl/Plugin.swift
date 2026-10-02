// Plugin.swift
// XT Copyright© 2026; Electric Bolt Limited.

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct InterruptMacroPluginImpl: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        InterruptMacro.self
    ]
}
