// FileDateTime.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

public class FileDateTime {

    /// - Parameter hours: 0-23 hour
    /// - Parameter minutes: 0-59 minute
    /// - Parameter seconds: 0-29 (seconds/2)
    /// - Parameter year: year-1980
    /// - Parameter month: 1-12 month
    /// - Parameter day: 1-31 day

    public init(_ hours: UInt8, _ minutes: UInt8, _ seconds: UInt8, _ year: UInt8, _ month: UInt8, _ day: UInt8) {
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        self.year = year
        self.month = month
        self.day = day
    }

    public init(_ lastModifiedTime: Date) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second, .year, .month, .day], from: lastModifiedTime)
        self.hours = UInt8(components.hour!)
        self.minutes = UInt8(components.minute!)
        self.seconds = UInt8(components.second! / 2)
        self.year = UInt8(components.year! - 1980)
        self.month = UInt8(components.month!)
        self.day = UInt8(components.day!)
    }

    public func toDOSTime() -> UInt16 {
        return FileDateTime.toDOSTime(hours, minutes, seconds)
    }

    public func toDOSDate() -> UInt16 {
        return FileDateTime.toDOSDate(year, month, day)
    }

    public static func toDOSTime(_ hours: UInt8, _ minutes: UInt8, _ seconds: UInt8) -> UInt16 {
        return (UInt16(hours) << 11) & 0b1111_1000_0000_0000 |
               (UInt16(minutes) << 5) & 0b0000_0111_1110_0000 |
               UInt16(seconds) & 0b0000_0000_0001_1111
    }

    public static func toDOSDate(_ year: UInt8, _ month: UInt8, _ day: UInt8) -> UInt16 {
        return (UInt16(year) << 9) & 0b1111_1110_0000_0000 |
               (UInt16(month) << 5) & 0b0000_0001_1110_0000 |
               UInt16(day) & 0b0000_0000_0001_1111
    }

    // MARK: - Internal

    private var hours: UInt8
    private var minutes: UInt8
    private var seconds: UInt8
    private var year: UInt8
    private var month: UInt8
    private var day: UInt8
}
