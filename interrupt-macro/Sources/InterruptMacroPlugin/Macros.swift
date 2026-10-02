// Macros.swift
// XT Copyright© 2026; Electric Bolt Limited.

@attached(peer, names: arbitrary)
public macro Interrupt(interrupt: UInt8? = nil, function: UInt8? = nil, subfunction: UInt8? = nil, description: String) =
    #externalMacro(module: "InterruptMacroPluginImpl", type: "InterruptMacro"
)
