// Types.h
// XT Copyright © 2026; Electric Bolt Limited.

#import "Foundation/Foundation.h"

typedef uint8_t BYTE;
typedef uint16_t WORD;
typedef uint32_t DWORD;

/// Swift has no ability to adjust the packing of a struct so the [un]official way is to declare them in C:
/// https://forums.swift.org/t/ability-to-pack-order-and-align-certain-types-of-structs-like-in-c/2101/2

#pragma pack(push, 1)

/// Display Parameter Block for IOCTL 0x4407 function 0x7F

struct _DPB {
    BYTE level;
    BYTE reserved1;
    WORD lengthOfData;
    WORD controlFlags;
    BYTE modeType;
    BYTE reserved2;
    WORD colors;
    WORD pixelColumns;
    WORD pixelRows;
    WORD characterColumns;
    WORD characterRows;
};

/// BIOS Data Area

struct _BDA {
    WORD com1Port;                 // 40:00 - COM1 port address
    WORD com2Port;                 // 40:02 - COM2 port address
    WORD com3Port;                 // 40:04 - COM3 port address
    WORD com4Port;                 // 40:06 - COM4 port address
    WORD lpt1Port;                 // 40:08 - LPT1 port address
    WORD lpt2Port;                 // 40:0A - LPT2 port address
    WORD lpt3Port;                 // 40:0C - LPT3 port address
    WORD lpt4PortOrEbdaSeg;        // 40:0E - LPT4 port address (except PS/2);
                                   //         PS/2: Extended BIOS Data Area segment

    WORD equipmentFlags;           // 40:10 - Equipment list flags (see INT 11)

    BYTE pcjrIrKeyboardErrorCount; // 40:12 - PCjr: infrared keyboard link error count
    WORD memorySizeKb;             // 40:13 - Memory size in Kbytes (see INT 12)

    BYTE reserved15;               // 40:15 - Reserved
    BYTE ps2BiosControlFlags;      // 40:16 - PS/2 BIOS control flags

    BYTE kbFlags0;                 // 40:17 - Keyboard flag byte 0
    BYTE kbFlags1;                 // 40:18 - Keyboard flag byte 1
    BYTE altKeypadEntry;           // 40:19 - Storage for alternate keypad entry

    WORD kbBufferHeadOffset;       // 40:1A - Offset from 40:00 to keyboard buffer head
    WORD kbBufferTailOffset;       // 40:1C - Offset from 40:00 to keyboard buffer tail
    BYTE kbBuffer[32];             // 40:1E - Keyboard buffer (circular queue buffer)

    BYTE driveRecalStatus;         // 40:3E - Drive recalibration status
    BYTE disketteMotorStatus;      // 40:3F - Diskette motor status

    BYTE motorShutoffCounter;      // 40:40 - Motor shutoff counter (decremented by INT 8)
    BYTE lastDisketteStatus;       // 40:41 - Status of last diskette operation (see INT 13,1)
    BYTE necFdcStatus[7];          // 40:42 - NEC diskette controller status (see FDC)

    BYTE currentVideoMode;         // 40:49 - Current video mode (see VIDEO MODE)
    WORD screenColumns;            // 40:4A - Number of screen columns
    WORD videoRegenBufferSize;     // 40:4C - Size of current video regen buffer in bytes
    WORD videoPageOffset;          // 40:4E - Offset of current video page in video regen buffer

    WORD cursorPosition[8];        // 40:50 - Cursor position of pages 1-8
                                   //         high byte = row, low byte = column

    BYTE cursorEndScanLine;        // 40:60 - Cursor ending (bottom) scan line (don't modify)
    BYTE cursorStartScanLine;      // 40:61 - Cursor starting (top) scan line (don't modify)
    BYTE activeDisplayPage;        // 40:62 - Active display page number
    WORD crtBasePort;              // 40:63 - Base port address for active 6845 CRT controller
                                   //         (3B4h = mono, 3D4h = color)
    BYTE crtModeControlReg;        // 40:65 - 6845 CRT mode control register value (port 3x8h)
    BYTE cgaColorPaletteMask;      // 40:66 - CGA current color palette mask setting (port 3D9h)

    BYTE resetVector[5];           // 40:67 - CS:IP for 286 return from protected mode (dword); or
                                   //         Temp storage for SS:SP during shutdown (dword); or
                                   //         Day counter on all products after AT (dword); or
                                   //         PS/2 pointer to reset code with memory preserved (dword);
                                   //         plus (pre-AT) 5 bytes of Cassette tape control

    DWORD dailyTimerCounter;       // 40:6C - Daily timer counter, zero at midnight;
                                   //         incremented by INT 8; read/set by INT 1A
    BYTE clockRolloverFlag;        // 40:70 - Clock rollover flag, set when 40:6C exceeds 24 hrs
    BYTE ctrlBreakFlag;            // 40:71 - BIOS break flag, bit 7 set if Ctrl-Break ever hit
    WORD softResetFlag;            // 40:72 - Soft reset flag via Ctrl-Alt-Del or JMP FFFF:0
                                   //         1234h=bypass mem test, 4321h=preserve memory,
                                   //         5678h=suspend, 9ABCh=mfg test, ABCDh=POST loop

    BYTE lastHardDiskStatus;       // 40:74 - Status of last hard disk operation (see INT 13,1)
    BYTE numHardDisks;             // 40:75 - Number of hard disks attached
    BYTE xtFixedDiskControlByte;   // 40:76 - XT fixed disk drive control byte
    BYTE fixedDiskAdapterOffset;   // 40:77 - Port offset to current fixed disk adapter

    BYTE lptTimeout[4];            // 40:78 - Time-out values for LPT1-LPT3(-LPT4 except PS/2)
    BYTE comTimeout[4];            // 40:7C - Time-out values for COM1-COM4

    WORD kbBufferStartOffset;      // 40:80 - Keyboard buffer start offset (seg=40h)
    WORD kbBufferEndOffset;        // 40:82 - Keyboard buffer end offset (seg=40h)

    BYTE screenRows;               // 40:84 - Rows on the screen (less 1, EGA+)

    BYTE charMatrixHeightLo;       // 40:85 - Point height of character matrix (EGA+, low byte);
                                   //         PCjr: character to repeat for typematic action
    BYTE charMatrixHeightHi;       // 40:86 - Point height of character matrix (EGA+, high byte);
                                   //         PCjr: initial delay before repeat key action begins

    BYTE videoModeOptions;         // 40:87 - Video mode options (EGA+);
                                   //         PCjr: current Fn function key number

    BYTE egaFeatureBitSwitches;    // 40:88 - EGA feature bit switches, emulated on VGA;
                                   //         PCjr: third keyboard status byte

    BYTE videoDisplayDataArea;     // 40:89 - Video display data area (MCGA and VGA)
    BYTE dccTableIndex;            // 40:8A - Display Combination Code (DCC) table index (EGA+)

    BYTE lastDisketteDataRate;     // 40:8B - Last diskette data rate selected
    BYTE hardDiskStatus;           // 40:8C - Hard disk status returned by controller
    BYTE hardDiskError;            // 40:8D - Hard disk error returned by controller
    BYTE hardDiskIntFlag;          // 40:8E - Hard disk interrupt control flag (bit7=working int)
    BYTE comboHardFloppyCard;      // 40:8F - Combination hard/floppy disk card when bit 0 set

    BYTE driveMediaState[4];       // 40:90 - Drive 0,1,2,3 media state

    BYTE trackSeekedDrive0;        // 40:94 - Track currently seeked to on drive 0
    BYTE trackSeekedDrive1;        // 40:95 - Track currently seeked to on drive 1

    BYTE keyboardModeType;         // 40:96 - Keyboard mode/type
    BYTE keyboardLedFlags;         // 40:97 - Keyboard LED flags

    DWORD userWaitCompleteFlagPtr; // 40:98 - Pointer to user wait complete flag
    DWORD userWaitTimeoutUs;       // 40:9C - User wait time-out value in microseconds

    BYTE rtcWaitFunctionFlag;      // 40:A0 - RTC wait function flag
    BYTE lanaDmaChannelFlags;      // 40:A1 - LANA DMA channel flags
    BYTE lanaStatus[2];            // 40:A2 - Status of LANA 0,1

    DWORD savedHardDiskIntVector;  // 40:A4 - Saved hard disk interrupt vector
    DWORD videoSaveOverridePtr;    // 40:A8 - BIOS Video Save/Override Pointer Table address

    BYTE reservedAC[8];            // 40:AC - Reserved

    BYTE kbNmiControlFlags;        // 40:B4 - Keyboard NMI control flags (Convertible)
    DWORD kbBreakPendingFlags;     // 40:B5 - Keyboard break pending flags (Convertible)
    BYTE port60Queue;              // 40:B9 - Port 60 single byte queue (Convertible)
    BYTE scanCodeLastKey;          // 40:BA - Scan code of last key (Convertible)
    BYTE nmiBufferHeadPtr;         // 40:BB - NMI buffer head pointer (Convertible)
    BYTE nmiBufferTailPtr;         // 40:BC - NMI buffer tail pointer (Convertible)
    BYTE nmiScanCodeBuffer[16];    // 40:BD - NMI scan code buffer (Convertible)

    BYTE reservedCD;               // 40:CD - Reserved (gap before day counter)
    WORD dayCounter;               // 40:CE - Day counter (Convertible and after)

    BYTE reservedD0[32];           // 40:D0 - Reserved/unused

    BYTE intraAppCommArea[16];     // 40:F0 - Intra-Applications Communications Area
                                   //         (IBM Tech Ref incorrectly locates this at 50:F0-50:FF)
};

/// Memory Control Block

struct _MCB {
    BYTE type;
    WORD owner;
    WORD size;
    BYTE unused[3];
    BYTE program[8];
};

/// Program Segment Prefix

struct _PSP {
    BYTE int20[2];
    WORD nextSeg;
    BYTE reserved1;
    BYTE dispatchCall[5];
    DWORD programTermination;
    DWORD breakpointHandler;
    DWORD criticalErrorHandler;
    WORD parentPSPSeg;
    BYTE jobFileTable[20];
    WORD environmentSeg;
    DWORD savedStackInt21;
    WORD sizeOfJFT;
    DWORD pointerToJFT;
    DWORD pointerToPreviousPSP;
    BYTE reserved2[4];
    WORD dosVersionToReturn;
    BYTE reserved3[14];
    BYTE int21retf[3];
    BYTE reserved4[2];
    BYTE reserved5[7];
    BYTE fcb1[16];
    BYTE fcb2[20];
    BYTE commandLineLength;
    BYTE commandLine[127];
};

/// .EXE file header

struct _EXE {
    BYTE signature[2];
    WORD lastPageSize;
    WORD pages;
    WORD relocationEntries;
    WORD paragraphsInHeader;
    WORD paragraphsForUninitializedData;
    WORD paragraphsToConstrainMemory;
    WORD relativeSS;
    WORD SP;
    WORD checksum;
    WORD IP;
    WORD relativeCS;
    WORD offsetFirstRelocationItem;
    WORD overlayNumber;
};

/// List of lists

struct _SysInitVars {
    BYTE reserved[14];
    WORD firstMCBSegment;                   // Offset -2
    DWORD DPBChain;                         // Offset 0
    DWORD SFTChain;                         // Offset 4
    DWORD clockDevice;
    DWORD conDevice;
    WORD maxSectorSize;
    DWORD bufferChain;
    DWORD CDSList;
    DWORD FCBChain;
    WORD FCBKeepCount;
    BYTE blockDeviceCount;
    BYTE CDSCount;
    DWORD deviceChain;
    WORD nullDeviceAttribute;
    WORD nullDeviceStrategyEntryPoint;
    WORD nullDeviceInterruptEntryPoint;
    BYTE nullDeviceName[8];
    BYTE spliceIndicator;
    WORD DOSSizeInParagraphs;
    DWORD DOSServiceRoutineEntry;
    DWORD IFSChain;
    WORD buffer;
    WORD lastDrive;
    BYTE bootDrive;
    BYTE machine386;
    WORD extendedMemorySize;
    BYTE reserved1[11];
};

/// Disk Transfer Area

struct _DTA {
    BYTE searchAttribute;
    BYTE searchDrive;
    BYTE searchName[11];
    WORD directoryEntryNumber;
    WORD startingClusterNumber;
    WORD internalId;
    WORD reserved1;
    BYTE fileAttribute;
    WORD fileTime;
    WORD fileDate;
    DWORD fileSize;
    BYTE fileName[11];
};

#pragma pack(pop)
