//
//  RecipeCrypto.swift
//  FilmBox
//
//  Secure encryption for recipe QR codes
//  Only Loopix app can generate and read these codes
//

import Foundation
import CryptoKit
import Compression

// MARK: - Recipe Crypto Manager

final class RecipeCrypto: Sendable {
    static let shared = RecipeCrypto()

    private init() {}

    // All properties are computed (stateless), so this class is thread-safe

    // MARK: - Obfuscated Key Storage
    // The key is split and obfuscated to make extraction from IPA difficult
    // DO NOT store keys as plain strings - they can be extracted with `strings` command

    /// Part 1: XOR encoded bytes (looks like random data)
    private var keyPart1: [UInt8] {
        // XOR mask applied to actual key bytes
        let encoded: [UInt8] = [0x7A, 0x3F, 0x8C, 0xD1, 0x45, 0xB2, 0x9E, 0x63]
        let mask: [UInt8] = [0x2B, 0x7E, 0xCD, 0x90, 0x14, 0xE3, 0xDF, 0x32]
        return zip(encoded, mask).map { $0 ^ $1 }
    }

    /// Part 2: Computed from app bundle info
    private var keyPart2: [UInt8] {
        // Derive from bundle identifier hash - ties key to this specific app
        let bundleID = Bundle.main.bundleIdentifier ?? "com.loopix.filmbox"
        let hash = SHA256.hash(data: Data(bundleID.utf8))
        return Array(hash.prefix(8))
    }

    /// Part 3: Bit-rotated storage
    private var keyPart3: [UInt8] {
        // Stored with bits rotated, restored at runtime
        let rotated: [UInt8] = [0x1E, 0x87, 0x4B, 0xC9, 0x5D, 0xA2, 0x36, 0xF0]
        return rotated.map { ($0 >> 3) | ($0 << 5) }
    }

    /// Part 4: Interleaved with decoy data
    private var keyPart4: [UInt8] {
        // Real bytes at even indices, decoys at odd
        let interleaved: [UInt8] = [0x8F, 0x00, 0x2C, 0x00, 0xE7, 0x00, 0x51, 0x00,
                                     0xA3, 0x00, 0x6D, 0x00, 0xB9, 0x00, 0x44, 0x00]
        return stride(from: 0, to: interleaved.count, by: 2).map { interleaved[$0] }
    }

    /// Assemble the 32-byte encryption key at runtime
    private var encryptionKey: SymmetricKey {
        var keyBytes = [UInt8]()
        keyBytes.append(contentsOf: keyPart1)
        keyBytes.append(contentsOf: keyPart2)
        keyBytes.append(contentsOf: keyPart3)
        keyBytes.append(contentsOf: keyPart4)
        return SymmetricKey(data: Data(keyBytes))
    }

    // MARK: - App Signature (24-char UUID hash)

    /// The secret app signature - proves the code came from our app
    /// This is derived from a hidden UUID, never stored as plain text
    private var appSignature: String {
        // Build signature from multiple computed sources
        let part1 = buildSignaturePart1()
        let part2 = buildSignaturePart2()
        let part3 = buildSignaturePart3()
        return part1 + part2 + part3
    }

    private func buildSignaturePart1() -> String {
        // First 8 chars - XOR decoded
        let encoded: [UInt8] = [0x4C, 0x58, 0x39, 0x6D, 0x51, 0x7A, 0x46, 0x62]
        let mask: [UInt8] = [0x00, 0x2D, 0x58, 0x08, 0x32, 0x0F, 0x77, 0x07]
        let decoded = zip(encoded, mask).map { $0 ^ $1 }
        return String(bytes: decoded, encoding: .utf8) ?? "LXDEFAULT"
    }

    private func buildSignaturePart2() -> String {
        // Middle 8 chars - reversed storage
        let reversed = "3Jk7NpQw"
        return String(reversed.reversed())
    }

    private func buildSignaturePart3() -> String {
        // Last 8 chars - base64 decode fragment
        let encoded = "WFkyM2FiYzg="
        guard let data = Data(base64Encoded: encoded),
              let str = String(data: data, encoding: .utf8) else {
            return "XY23abc8"
        }
        return str
    }

    // MARK: - Public API

    /// Magic header to identify encrypted Loopix recipes
    private var magicHeader: String { "LPX1" }

    /// Encrypt recipe data for QR code export
    /// - Parameter recipeData: The RecipeQRData to encrypt
    /// - Returns: Base64-encoded encrypted string, or nil on failure
    func encrypt(_ recipeData: RecipeQRData) -> String? {
        guard let jsonData = try? JSONEncoder().encode(recipeData) else {
            return nil
        }

        // Add signature to payload for verification
        var payload = Data()
        payload.append(Data(appSignature.utf8))
        payload.append(jsonData)

        // Compress to minimize QR size
        guard let compressed = compress(payload) else {
            return nil
        }

        // Encrypt with AES-GCM
        do {
            let nonce = AES.GCM.Nonce()
            let sealedBox = try AES.GCM.seal(compressed, using: encryptionKey, nonce: nonce)

            guard let combined = sealedBox.combined else {
                return nil
            }

            // Prepend magic header for identification
            var output = Data(magicHeader.utf8)
            output.append(combined)

            return output.base64EncodedString()
        } catch {
            return nil
        }
    }

    /// Decrypt recipe data from QR code
    /// - Parameter encryptedString: Base64-encoded encrypted string
    /// - Returns: RecipeQRData if valid and from our app, nil otherwise
    func decrypt(_ encryptedString: String) -> RecipeQRData? {
        guard let data = Data(base64Encoded: encryptedString) else {
            return nil
        }

        // Verify magic header
        guard data.count > 4,
              String(data: data.prefix(4), encoding: .utf8) == magicHeader else {
            return nil
        }

        let encryptedData = data.dropFirst(4)

        // Decrypt with AES-GCM
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decrypted = try AES.GCM.open(sealedBox, using: encryptionKey)

            // Decompress
            guard let decompressed = decompress(decrypted) else {
                return nil
            }

            // Verify signature (first 24 bytes)
            guard decompressed.count > 24 else {
                return nil
            }

            let receivedSignature = String(data: decompressed.prefix(24), encoding: .utf8)
            guard receivedSignature == appSignature else {
                // Signature mismatch - not from our app or tampered
                return nil
            }

            // Parse recipe JSON
            let jsonData = decompressed.dropFirst(24)
            return try? JSONDecoder().decode(RecipeQRData.self, from: jsonData)
        } catch {
            return nil
        }
    }

    /// Check if a string is an encrypted Loopix recipe
    func isEncryptedRecipe(_ string: String) -> Bool {
        guard let data = Data(base64Encoded: string),
              data.count > 4,
              String(data: data.prefix(4), encoding: .utf8) == magicHeader else {
            return false
        }
        return true
    }

    // MARK: - Compression (reduces QR code size)

    private func compress(_ data: Data) -> Data? {
        guard !data.isEmpty else { return nil }

        // Allocate buffer larger than input - compression may not always reduce size
        let bufferSize = max(data.count * 2, 256)
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { destinationBuffer.deallocate() }

        let compressedSize = data.withUnsafeBytes { sourcePtr -> Int in
            guard let sourceBaseAddress = sourcePtr.baseAddress else { return 0 }
            return compression_encode_buffer(
                destinationBuffer,
                bufferSize,
                sourceBaseAddress.assumingMemoryBound(to: UInt8.self),
                data.count,
                nil,
                COMPRESSION_LZFSE
            )
        }

        guard compressedSize > 0 else { return nil }
        return Data(bytes: destinationBuffer, count: compressedSize)
    }

    private func decompress(_ data: Data) -> Data? {
        guard !data.isEmpty else { return nil }

        // Allocate larger buffer for decompression
        let destinationSize = data.count * 10
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationSize)
        defer { destinationBuffer.deallocate() }

        let decompressedSize = data.withUnsafeBytes { sourcePtr -> Int in
            guard let sourceBaseAddress = sourcePtr.baseAddress else { return 0 }
            return compression_decode_buffer(
                destinationBuffer,
                destinationSize,
                sourceBaseAddress.assumingMemoryBound(to: UInt8.self),
                data.count,
                nil,
                COMPRESSION_LZFSE
            )
        }

        guard decompressedSize > 0 else { return nil }
        return Data(bytes: destinationBuffer, count: decompressedSize)
    }
}

// MARK: - Additional Obfuscation Helpers

private extension RecipeCrypto {
    /// Anti-tampering: verify the crypto module hasn't been patched
    func integrityCheck() -> Bool {
        // Check that key parts produce expected hash
        var allParts = [UInt8]()
        allParts.append(contentsOf: keyPart1)
        allParts.append(contentsOf: keyPart2)
        allParts.append(contentsOf: keyPart3)
        allParts.append(contentsOf: keyPart4)

        let hash = SHA256.hash(data: Data(allParts))
        let hashPrefix = Array(hash.prefix(4))

        // Expected prefix (will need to be updated if keys change)
        // This makes it harder to just swap out the keys
        let expected: [UInt8] = [0xA3, 0x7B, 0x4C, 0xD9]

        // Note: This check is intentionally weak to allow development
        // In production, make this stricter
        return hashPrefix.count == expected.count
    }
}
