# XT (xt-swift-usermode)

MS-DOS command line program user mode emulator for macOS 26+ (Apple Silicon only)

### Contents

[What is XT?](#what-is-xt)  
[Installing XT](#installing-xt)  
[Running MS-DOS command line programs](#running-ms-dos-command-line-programs)  
[Converting MS-DOS command line programs into native macOS command line apps](#converting-ms-dos-command-line-programs-into-native-macos-command-line-apps)  
[Extending/Developing XT](#extendingdeveloping-xt)  
&nbsp;&nbsp;[Adding DOS or BIOS interrupt handling functions to allow additional MS-DOS programs to run](#adding-dos-or-bios-interrupt-handling-functions-to-allow-additional-ms-dos-programs-to-run)  
&nbsp;&nbsp;[Implemented DOS and BIOS interrupt handling functions](#implemented-dos-and-bios-interrupt-handling-functions)  

### What is XT?

**Run MS-DOS command line programs** - a user mode emulator similar to WINE or QEMU but for command line MS-DOS programs. Loads and executes `.COM` and `.EXE` files. MS-DOS interrupts are translated to the appropriate macOS APIs. See [Running MS-DOS command line programs](#running-ms-dos-command-line-programs) for a compatible list of programs. 

```bash
[user@host ~]# xt run TASM.EXE

Turbo Assembler  Version 3.2  Copyright (c) 1988, 1992 Borland International
Syntax:  TASM [options] source [,object] [,listing] [,xref]
/a,/s         Alphabetic or Source-code segment ordering
/c            Generate cross-reference in listing
/dSYM[=VAL]   Define symbol SYM = 0, or = value VAL
/e,/r         Emulated or Real floating-point instructions
/h,/?         Display this help screen
/iPATH        Search PATH for include files
/jCMD         Jam in an assembler directive CMD (eg. /jIDEAL)
/kh#          Hash table capacity # symbols
...

[user@host ~]# xt run TASM.EXE MORE.ASM

Turbo Assembler  Version 3.2  Copyright (c) 1988, 1992 Borland International

Assembling file:   MORE.ASM
Error messages:    None
Warning messages:  None
Passes:            1
Remaining memory:  795k

[user@host ~]#
```

It is **not** a goal of XT to evolve into runnning full screen text or graphical programs. There are other solutions for this such as [QEMU](https://www.qemu.org/), [dosbox-x](https://dosbox-x.com/) or [MartyPC](https://github.com/dbalsom/martypc).

### Installing XT

**1.** Use the GitHub [Releases](https://github.com/electricbolt/xt-swift-usermode/releases) link to download `xt-2.0.0.pkg`. These builds are signed by Electric Bolt Limited and notarised by Apple.

**2.** In Finder, double tap on `xt-2.0.0.pkg`.

**3.** Follow the prompts to install `xt` into `/usr/local/bin`. You do **not** need to modify your PATH.

### Running MS-DOS command line programs

XT can directly run in a command shell/terminal, the following MS-DOS command line programs (and likely many more):

| **Program** | **Version** | **File** | **Inc** | **Notes** |             
|-------------|-------------|----------|---------|-----------| 
| Microsoft Assembler | 5.10  | MASM.EXE    | ✓ | [MIT licence](https://github.com/microsoft/MS-DOS) |
| Microsoft Linker    | 3.65  | LINK.EXE    | ✓ | [MIT licence](https://github.com/microsoft/MS-DOS) |
| UD MEM              | -     | MEM.EXE     | ✓ | From UNDOCUMENTED DOS book listing |                
| INFOEXE             | 1.0   | INFOEXE.EXE | ✓ | Information about an EXE file by Fabrice Bellard |
| Turbo Assembler     | 2.01  | TASM.EXE    |   |   |
| Turbo Assembler     | 3.2   | TASM.EXE    |   |   |
| Turbo Linker        | 3.0.1 | TLINK.EXE   |   | 3.0.1 is the last version compatible with 8086/8088 |
| Turbo Librarian     | 3.0   | TLIB.EXE    |   |   |
| Turbo Pascal        | 5.5   | TPC.EXE     |   |   |
| Turbo Pascal        | 6.0   | TPC.EXE     |   | 6.0 is the last version compatible with 8086/8088   |

`xt run [-c dir] program [command line arguments]`

The optional `-c dir` is the host directory that will be the root of the emulated `C:` drive. If not specified, then the current working directory will be used.

All directories and filenames provided to a MS-DOS command line program should conform to 8.3 character limitation and be uppercase.

Because there is no Video RAM, ROM BIOS, Option ROMs or DOS kernel in memory, programs get almost the entire 1MB address space to run:

```
InterruptVectorTable   0000:0000 (00000 0)       - 0000:03FF (003FF 1023)    size 1024 bytes
BIOSDataArea           0040:0000 (00400 1024)    - 0040:00FF (004FF 1279)    size 256 bytes
DOSVariables           0050:0000 (00500 1280)    - 0050:0061 (00561 1377)    size 98 bytes
DOSErrorTable          0057:0000 (00570 1392)    - 0057:09BF (00F2F 3887)    size 2496 bytes
EnvironmentVariables   00F3:0000 (00F30 3888)    - 00F3:00FF (0102F 4143)    size 256 bytes
Program                0103:0000 (01030 4144)    - FFFD:000F (FFFDF 1048543) size 1044400 bytes
  MCB                  0103:0000 (01030 4144)    - 0103:000F (0103F 4159)    size 16 bytes
  PSP                  0104:0000 (01040 4160)    - 0104:00FF (0113F 4415)    size 256 bytes
EndOfMemory            FFFE:0000 (FFFE0 1048544) - FFFE:001F (FFFFF 1048575) size 32 bytes

```

### Converting MS-DOS command line programs into native macOS command line apps

`xt app [-s identity] program output`

XT can convert `.EXE` and `.COM` MS-DOS command line programs into native macOS command line apps. The program cannot be larger than 128KB (131072 bytes) after compression (LZMA). On average we see a 1.8:1 compression ratio. Therefore the theortical largest MS-DOS command line program you could convert successfully would be ~230KB before compression. 

By default Adhoc code signing is performed.

```bash
[user@host ~]# xt app TASM.EXE tasm

Creating app tasm
Signing app tasm
Making app executable tasm

[user@host ~]# tasm

Turbo Assembler  Version 3.2  Copyright (c) 1988, 1992 Borland International
Syntax:  TASM [options] source [,object] [,listing] [,xref]
/a,/s         Alphabetic or Source-code segment ordering
/c            Generate cross-reference in listing
/dSYM[=VAL]   Define symbol SYM = 0, or = value VAL
...
```

To codesign with a specific certificate identity from your Keychain use the `-s identity` option:

```bash
[user@host ~]# xt app -s "Apple Development: Joe Bloggs (5DHMUFC6F1)" TASM.EXE tasm
```

### Extending/Developing XT ###

XT (xt-swift-usermode) was developed with Xcode 27. There is only one direct SPM dependency - [xt-swift-cpu8088](https://github.com/electricbolt/xt-swift-cpu8088).

#### Unit tests

Programs with ✓ in the Inc column in the table above are in the repos `bin/` folder. To run the comprehensive unit test suite, download programs not included and place into the appropriate `bin/` folders.

#### Adding DOS or BIOS interrupt handling functions to allow additional MS-DOS programs to run

**1․** Try running your MS-DOS command line program. Any unhandled DOS or BIOS interrupts cause XT to terminate and display an error message. For the following example, you would need to implement an interrupt handling function for Interrupt 0x10, Function 0x0F - Get current video mode:

```text
Unhandled interrupt 10
CS=0000 IP=0000 AX=0F00 BX=0000 CX=0000 DX=00CE SI=01EF DI=0410 BP=0000 SP=0FF4 DS=024C ES=0000 SS=035C FLAGS=AF
```

**2․** Add your DOS or BIOS interrupt handling function to an existing class (assuming the same category of functionality) or create a new class.

**3․** Ensure your DOS or BIOS interrupt handling function has the appropriate annotations: `
@Interrupt`, `@AX`, `@BX`, `@ASCIZ` etc. See `Interrupts.swift` class comment for more details.

All `@Interrupt` functions are automatically discovered at startup of XT through the magic of Mach-O `@section` introspection (the same mechanism as used by Swift Testing).

```text
import Foundation
import InterruptMacroPlugin
import XTSwiftCPU8088

class BIOSVideo {

    @Interrupt(interrupt: 0x10, function: 0x0F, description: "Get current video mode")
    func getCurrentVideoMode(_ cpu: CPU) {
        cpu.reg.AH.setValue(80) // Number of character columns.
        cpu.reg.AL.setValue(0x07) // Display mode = 80x25 monochrome.
        cpu.reg.BH.setValue(0) // Active page.
    }
}
```

**4․** For debugging, enable Interrupt and CPU tracing by adding `-ti -tc trace.txt` command line  parameters. You can also modify `READ/WRITE/EXECUTE` permissions for each byte of memory to isolate program behavior, see `DOSVariables.swift` for implementation guidance.

#### Implemented DOS and BIOS interrupt handling functions

`xt int -md` outputs the following:

- **INT 10 function 00** - Set video mode
- **INT 10 function 01** - Set text-mode cursor shape
- **INT 10 function 02** - Set cursor position
- **INT 10 function 03** - Get cursor position
- **INT 10 function 05** - Select active display page
- **INT 10 function 06** - Scroll window up
- **INT 10 function 07** - Scroll window down
- **INT 10 function 08** - Read character and attribute at cursor position
- **INT 10 function 09** - Write character and attribute at cursor position
- **INT 10 function 0A** - Write character only at cursor position
- **INT 10 function 0E** - Teletype output
- **INT 10 function 0F** - Get current video mode
- **INT 11** - Get equipment list
- **INT 12** - Get memory size
- **INT 15 function C1** - Return extended BIOS data area
- **INT 1A function 00** - Get system time clock ticks
- **INT 20** - Terminate program
- **INT 21 function 00** - Terminate program
- **INT 21 function 02** - Write character to standard output
- **INT 21 function 09** - Write string to standard output
- **INT 21 function 0B** - Get STDIN status
- **INT 21 function 19** - Get current default drive
- **INT 21 function 1A** - Set disk transfer area address
- **INT 21 function 25** - Set interrupt vector
- **INT 21 function 2A** - Get system date
- **INT 21 function 2C** - Get system time
- **INT 21 function 2F** - Get disk transfer area address
- **INT 21 function 30** - Get DOS version
- **INT 21 function 3301** - Set extended break checking state
- **INT 21 function 35** - Get interrupt vector
- **INT 21 function 3700** - Get switch character
- **INT 21 function 38** - Get country specific information
- **INT 21 function 3C** - Create or truncate file
- **INT 21 function 3D** - Open existing file
- **INT 21 function 3E** - Close file
- **INT 21 function 3F** - Read from file or device
- **INT 21 function 40** - Write to file or device
- **INT 21 function 41** - Delete file
- **INT 21 function 42** - Set current file position
- **INT 21 function 4300** - Get file attributes
- **INT 21 function 4400** - IOCTL Get device information
- **INT 21 function 4401** - IOCTL Set device information
- **INT 21 function 4407** - IOCTL Get input/output status
- **INT 21 function 440C** - IOCTL Generic character device request
- **INT 21 function 48** - Allocate memory block
- **INT 21 function 49** - Free memory block
- **INT 21 function 4A** - Resize memory block
- **INT 21 function 4C** - Terminate program with exit code
- **INT 21 function 4E** - Find first matching file
- **INT 21 function 52** - Get List of Lists
- **INT 21 function 56** - Rename file
- **INT 21 function 5700** - Get file's date and time
- **INT 21 function 62** - Get current PSP
- **INT 21 function 6300** - Get lead byte table address
- **INT 2F function 122E** - Get or set error table address

### Looking for a Java port?

xt-swift-usermode is a port of my [Java based CPU emulator and MS-DOS command line program user mode emulator](https://github.com/electricbolt/XT).
