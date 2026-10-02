// FileAttribute.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

public enum FileAttribute: UInt8, CaseIterable {
    
    case readOnly = 0x01;
    case hidden = 0x02;
    case system = 0x04;
    case volumeLabel = 0x08;
    case directory = 0x10;
    case archive = 0x20;
}
