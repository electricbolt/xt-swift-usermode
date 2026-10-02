// String+CP437.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

public extension String {

    /// Decodes a Data buffer encoded in Code Page 437 (CP437) into a standard Swift String.

    init(fromCP437 data: [UInt8]) {
        // Lookup table for CP437 bytes 128 to 255 mapped to Unicode characters
        let table: [Character] = [
            "Ç", "ü", "é", "â", "ä", "à", "å", "ç", "ê", "ë", "è", "ï", "î", "ì", "Ä", "Å",
            "É", "æ", "Æ", "ô", "ö", "ò", "û", "ù", "ÿ", "Ö", "Ü", "¢", "£", "¥", "₧", "ƒ",
            "á", "í", "ó", "ú", "ñ", "Ñ", "ª", "º", "¿", "⌐", "¬", "½", "¼", "¡", "«", "»",
            "░", "▒", "▓", "│", "┤", "╡", "╢", "╖", "╕", "╣", "║", "╗", "╝", "╜", "╛", "┐",
            "└", "┴", "┬", "├", "─", "┼", "╞", "╟", "╚", "╔", "╩", "╦", "╠", "═", "╬", "╧",
            "╨", "╤", "╥", "╙", "╘", "╒", "╓", "╫", "╪", "┘", "┌", "█", "▄", "▌", "▐", "▀",
            "α", "ß", "Γ", "π", "Σ", "σ", "µ", "τ", "Φ", "Θ", "Ω", "δ", "∞", "φ", "ε", "∩",
            "≡", "±", "≥", "≤", "⌠", "⌡", "÷", "≈", "°", "∙", "·", "√", "ⁿ", "²", "■", " "
        ]

        var characters = [Character]()
        characters.reserveCapacity(data.count)

        for byte in data {
            if byte < 128 {
                // Standard ASCII range (0-127)
                characters.append(Character(UnicodeScalar(byte)))
            } else {
                // Extended CP437 range (128-255)
                let index = Int(byte) - 128
                characters.append(table[index])
            }
        }

        self = String(characters)
    }
}
