// BIOSDataArea.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088

/// Well known variables that the BIOS exposes. Always located at 0040:0000.

public class BIOSDataArea: MemorySpace {

    public init(_ memory: Memory, _ paragraph: ParagraphAlloc) {
        assert(ofs.com1Port == 0x00)
        assert(ofs.dailyTimerCounter == 0x6C)
        assert(ofs.intraAppCommArea == 0xF0)
        assert(MemoryLayout<_BDA>.size == 256)

        super.init(memory, paragraph, MemoryLayout<_BDA>.size, Mirror(reflecting: ofs))

        self.dailyTimerCounterValue = timeInClockTicks()
        setDailyTimerCounter(dailyTimerCounterValue)

        removePermission()
        allowPermission(ofs.dailyTimerCounter, 4)
    }

    /// If required, will update the DWORD value in the BIOS data area `dailyTimerCounter` (0040:006C) with the new timer tick counter value.
    /// Occasionally called by `ProgramRunner.fetched` method. Better behaved programs should call Get system time clock ticks INT 1A function 00.

    public func updateTimerTick() {
        let now = timeInClockTicks()
        if now != dailyTimerCounterValue {
            setDailyTimerCounter(dailyTimerCounterValue)
        }
    }

    /// Returns the current timer tick counter value (DWORD). Unlike MS-DOS which starts from 0 when the PC is switched on,
    /// our timer tick counter value is based upon the current time.
    ///
    /// - returns DWORD value 0 ... 1573039 inclusive, which is 18.2 ticks/second over a 24 hour period.

    public func timeInClockTicks() -> UInt32 {
        var timeInfo = mach_timebase_info_data_t()
        mach_timebase_info(&timeInfo)
        let now = mach_absolute_time()
        let nanoseconds = now * UInt64(timeInfo.numer) / UInt64(timeInfo.denom)
        return UInt32((nanoseconds / 1_000_000 / 182) % 1_573_040)
    }

    // MARK: - Internal

    private var dailyTimerCounterValue: UInt32 = 0

    private struct Ofs {
        let com1Port = MemoryLayout<_BDA>.offset(of: \.com1Port)!
        let com2Port = MemoryLayout<_BDA>.offset(of: \.com2Port)!
        let com3Port = MemoryLayout<_BDA>.offset(of: \.com3Port)!
        let com4Port = MemoryLayout<_BDA>.offset(of: \.com4Port)!
        let lpt1Port = MemoryLayout<_BDA>.offset(of: \.lpt1Port)!
        let lpt2Port = MemoryLayout<_BDA>.offset(of: \.lpt2Port)!
        let lpt3Port = MemoryLayout<_BDA>.offset(of: \.lpt3Port)!
        let lpt4PortOrEbdaSeg = MemoryLayout<_BDA>.offset(of: \.lpt4PortOrEbdaSeg)!
        let equipmentFlags = MemoryLayout<_BDA>.offset(of: \.equipmentFlags)!
        let pcjrIrKeyboardErrorCount = MemoryLayout<_BDA>.offset(of: \.pcjrIrKeyboardErrorCount)!
        let memorySizeKb = MemoryLayout<_BDA>.offset(of: \.memorySizeKb)!
        let reserved15 = MemoryLayout<_BDA>.offset(of: \.reserved15)!
        let ps2BiosControlFlags = MemoryLayout<_BDA>.offset(of: \.ps2BiosControlFlags)!
        let kbFlags0 = MemoryLayout<_BDA>.offset(of: \.kbFlags0)!
        let kbFlags1 = MemoryLayout<_BDA>.offset(of: \.kbFlags1)!
        let altKeypadEntry = MemoryLayout<_BDA>.offset(of: \.altKeypadEntry)!
        let kbBufferHeadOffset = MemoryLayout<_BDA>.offset(of: \.kbBufferHeadOffset)!
        let kbBufferTailOffset = MemoryLayout<_BDA>.offset(of: \.kbBufferTailOffset)!
        let kbBuffer = MemoryLayout<_BDA>.offset(of: \.kbBuffer)!
        let driveRecalStatus = MemoryLayout<_BDA>.offset(of: \.driveRecalStatus)!
        let disketteMotorStatus = MemoryLayout<_BDA>.offset(of: \.disketteMotorStatus)!
        let motorShutoffCounter = MemoryLayout<_BDA>.offset(of: \.motorShutoffCounter)!
        let lastDisketteStatus = MemoryLayout<_BDA>.offset(of: \.lastDisketteStatus)!
        let necFdcStatus = MemoryLayout<_BDA>.offset(of: \.necFdcStatus)!
        let currentVideoMode = MemoryLayout<_BDA>.offset(of: \.currentVideoMode)!
        let screenColumns = MemoryLayout<_BDA>.offset(of: \.screenColumns)!
        let videoRegenBufferSize = MemoryLayout<_BDA>.offset(of: \.videoRegenBufferSize)!
        let videoPageOffset = MemoryLayout<_BDA>.offset(of: \.videoPageOffset)!
        let cursorPosition = MemoryLayout<_BDA>.offset(of: \.cursorPosition)!
        let cursorEndScanLine = MemoryLayout<_BDA>.offset(of: \.cursorEndScanLine)!
        let cursorStartScanLine = MemoryLayout<_BDA>.offset(of: \.cursorStartScanLine)!
        let activeDisplayPage = MemoryLayout<_BDA>.offset(of: \.activeDisplayPage)!
        let crtBasePort = MemoryLayout<_BDA>.offset(of: \.crtBasePort)!
        let crtModeControlReg = MemoryLayout<_BDA>.offset(of: \.crtModeControlReg)!
        let cgaColorPaletteMask = MemoryLayout<_BDA>.offset(of: \.cgaColorPaletteMask)!
        let resetVector = MemoryLayout<_BDA>.offset(of: \.resetVector)!
        let dailyTimerCounter = MemoryLayout<_BDA>.offset(of: \.dailyTimerCounter)!
        let clockRolloverFlag = MemoryLayout<_BDA>.offset(of: \.clockRolloverFlag)!
        let ctrlBreakFlag = MemoryLayout<_BDA>.offset(of: \.ctrlBreakFlag)!
        let softResetFlag = MemoryLayout<_BDA>.offset(of: \.softResetFlag)!
        let lastHardDiskStatus = MemoryLayout<_BDA>.offset(of: \.lastHardDiskStatus)!
        let numHardDisks = MemoryLayout<_BDA>.offset(of: \.numHardDisks)!
        let xtFixedDiskControlByte = MemoryLayout<_BDA>.offset(of: \.xtFixedDiskControlByte)!
        let fixedDiskAdapterOffset = MemoryLayout<_BDA>.offset(of: \.fixedDiskAdapterOffset)!
        let lptTimeout = MemoryLayout<_BDA>.offset(of: \.lptTimeout)!
        let comTimeout = MemoryLayout<_BDA>.offset(of: \.comTimeout)!
        let kbBufferStartOffset = MemoryLayout<_BDA>.offset(of: \.kbBufferStartOffset)!
        let kbBufferEndOffset = MemoryLayout<_BDA>.offset(of: \.kbBufferEndOffset)!
        let screenRows = MemoryLayout<_BDA>.offset(of: \.screenRows)!
        let charMatrixHeightLo = MemoryLayout<_BDA>.offset(of: \.charMatrixHeightLo)!
        let charMatrixHeightHi = MemoryLayout<_BDA>.offset(of: \.charMatrixHeightHi)!
        let videoModeOptions = MemoryLayout<_BDA>.offset(of: \.videoModeOptions)!
        let egaFeatureBitSwitches = MemoryLayout<_BDA>.offset(of: \.egaFeatureBitSwitches)!
        let videoDisplayDataArea = MemoryLayout<_BDA>.offset(of: \.videoDisplayDataArea)!
        let dccTableIndex = MemoryLayout<_BDA>.offset(of: \.dccTableIndex)!
        let lastDisketteDataRate = MemoryLayout<_BDA>.offset(of: \.lastDisketteDataRate)!
        let hardDiskStatus = MemoryLayout<_BDA>.offset(of: \.hardDiskStatus)!
        let hardDiskError = MemoryLayout<_BDA>.offset(of: \.hardDiskError)!
        let hardDiskIntFlag = MemoryLayout<_BDA>.offset(of: \.hardDiskIntFlag)!
        let comboHardFloppyCard = MemoryLayout<_BDA>.offset(of: \.comboHardFloppyCard)!
        let driveMediaState = MemoryLayout<_BDA>.offset(of: \.driveMediaState)!
        let trackSeekedDrive0 = MemoryLayout<_BDA>.offset(of: \.trackSeekedDrive0)!
        let trackSeekedDrive1 = MemoryLayout<_BDA>.offset(of: \.trackSeekedDrive1)!
        let keyboardModeType = MemoryLayout<_BDA>.offset(of: \.keyboardModeType)!
        let keyboardLedFlags = MemoryLayout<_BDA>.offset(of: \.keyboardLedFlags)!
        let userWaitCompleteFlagPtr = MemoryLayout<_BDA>.offset(of: \.userWaitCompleteFlagPtr)!
        let userWaitTimeoutUs = MemoryLayout<_BDA>.offset(of: \.userWaitTimeoutUs)!
        let rtcWaitFunctionFlag = MemoryLayout<_BDA>.offset(of: \.rtcWaitFunctionFlag)!
        let lanaDmaChannelFlags = MemoryLayout<_BDA>.offset(of: \.lanaDmaChannelFlags)!
        let lanaStatus = MemoryLayout<_BDA>.offset(of: \.lanaStatus)!
        let savedHardDiskIntVector = MemoryLayout<_BDA>.offset(of: \.savedHardDiskIntVector)!
        let videoSaveOverridePtr = MemoryLayout<_BDA>.offset(of: \.videoSaveOverridePtr)!
        let reservedAC = MemoryLayout<_BDA>.offset(of: \.reservedAC)!
        let kbNmiControlFlags = MemoryLayout<_BDA>.offset(of: \.kbNmiControlFlags)!
        let kbBreakPendingFlags = MemoryLayout<_BDA>.offset(of: \.kbBreakPendingFlags)!
        let port60Queue = MemoryLayout<_BDA>.offset(of: \.port60Queue)!
        let scanCodeLastKey = MemoryLayout<_BDA>.offset(of: \.scanCodeLastKey)!
        let nmiBufferHeadPtr = MemoryLayout<_BDA>.offset(of: \.nmiBufferHeadPtr)!
        let nmiBufferTailPtr = MemoryLayout<_BDA>.offset(of: \.nmiBufferTailPtr)!
        let nmiScanCodeBuffer = MemoryLayout<_BDA>.offset(of: \.nmiScanCodeBuffer)!
        let reservedCD = MemoryLayout<_BDA>.offset(of: \.reservedCD)!
        let dayCounter = MemoryLayout<_BDA>.offset(of: \.dayCounter)!
        let reservedD0 = MemoryLayout<_BDA>.offset(of: \.reservedD0)!
        let intraAppCommArea = MemoryLayout<_BDA>.offset(of: \.intraAppCommArea)!
    }
    private let ofs = Ofs()

    private func setDailyTimerCounter(_ value: UInt32) {
        setDoubleWord(ofs.dailyTimerCounter, value)
    }
}
