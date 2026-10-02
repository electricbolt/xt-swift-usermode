// SharingMode.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

public enum SharingMode: UInt8, CaseIterable {
    
    case compatibilityMode = 0
    case denyAll = 1
    case denyWrite = 2
    case denyRead = 3
    case denyNone = 4
}
