// EmbeddedProgram.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Foundation
import XTSwiftCPU8088
import InterruptMacroPlugin

public struct EmbeddedProgram {

    /// Creates a new macOS app based upon the XT app with the MS-DOS program embedded into it.

    public static func createApp(from programPath: String, _ signingIdentity: String, _ appPath: String) {
        do {
            let fileAttrs: [FileAttributeKey:Any] = try FileManager.default.attributesOfItem(atPath: programPath)
            let fileSize: Int64 = fileAttrs[.size] as! Int64
            if fileSize == 0 {
                print("Program \(programPath) cannot be empty")
                exit(255)
            }

            // Load MS-DOS program into memory.
            var programData = try Data(contentsOf: URL(fileURLWithPath: programPath))

            // Compress using zlib.
            programData = try (programData as NSData).compressed(using: .lzma) as Data

            if programData.count > 131072 {
                print("Program \(programPath) cannot be larger than 128KB (131072 bytes) after compression (\(programData.count) bytes)")
                exit(255)
            }

            // Load XT macOS app into memory.
            var xtData = try Data(contentsOf: Bundle.main.executableURL!)

            var match = Data([0xEF, 0xCD, 0xAB, 0x89, 0x67, 0x45, 0x23, 0x01] as [UInt8])
            match.append(Data(repeating: 0x00, count: 4096))
            let offset: Data.Index = xtData.firstRange(of: match)!.lowerBound

            let size: Data = int64ToDataLittleEndian(Int64(programData.count))

            xtData[offset..<offset + size.count] = size
            xtData[offset + size.count..<offset + size.count + programData.count] = programData

            print("Creating app \(appPath)")
            let url = URL(fileURLWithPath: appPath)
            try? xtData.write(to: url)

            print("Signing app \(appPath)")
            _ = try execute("/usr/bin/codesign", ["--remove-signature", url.path])
            _ = try execute("/usr/bin/codesign", ["-s", signingIdentity, url.path])

            print("Making app executable \(appPath)")
            // Apply r-w-x for Owner, r-x for Group and Others.
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        } catch {
            print("Could not create app - \(error)")
            exit(255)
        }
    }

    /// Returns any embedded program as an [UInt8]. If there is no embedded program the result will be an empty array.

    public static func getProgram() -> [UInt8] {
        assert(binSize == 131080)

        // Load the first 8 bytes from bin to get the embedded binary size
        let ptr = UnsafeBufferPointer(start: bin, count: Int(binSize))
        let loadedBinSize: UInt64 = ptr.span.withUnsafeBytes { buffer in
            buffer.load(as: UInt64.self)
        }
        if loadedBinSize == 0x0123456789ABCDEF {
            return []
        }

        do {
            let loadedBin: [UInt8] = Array(ptr[8..<8 + Int(loadedBinSize)])
            let decompressed: Data = try (Data(loadedBin) as NSData).decompressed(using: .lzma) as Data
            return [UInt8](decompressed)
        } catch {
            print("Could not load binary - \(error)")
            exit(255)
        }
    }

    // MARK: - internal

    private static func int64ToDataLittleEndian(_ value: Int64) -> Data {
        // Force the integer into little-endian representation
        var littleEndianValue: Int64 = value.littleEndian

        // Create a Data object from the bytes of the value
        return Data(bytes: &littleEndianValue, count: MemoryLayout<Int64>.size)
    }
}
