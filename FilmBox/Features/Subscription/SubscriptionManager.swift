//
//  SubscriptionManager.swift
//  FilmBox
//
//  StoreKit 2 subscription management
//

import Foundation
import StoreKit
import SwiftUI
import CryptoKit

// MARK: - Subscription Product IDs

enum SubscriptionProduct: String, CaseIterable {
    case yearlyPro = "com.filmbox.pro.yearly"

    var displayName: String {
        switch self {
        case .yearlyPro:
            return "FilmBox Pro"
        }
    }
}

// MARK: - Subscription Error

enum SubscriptionError: LocalizedError {
    case productNotFound
    case purchaseFailed
    case verificationFailed
    case userCancelled
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Subscription product not found"
        case .purchaseFailed:
            return "Purchase failed"
        case .verificationFailed:
            return "Could not verify purchase"
        case .userCancelled:
            return "Purchase was cancelled"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Subscription Manager

@available(iOS 17.0, *)
@MainActor
final class SubscriptionManager: ObservableObject {

    // MARK: - Singleton

    static let shared = SubscriptionManager()

    // MARK: - Gift Code (Friends & Family)

    /// HMAC-signed gift codes - format: loopix://gift/CODE-SIGNATURE
    /// Generate codes using: SubscriptionManager.generateGiftCode()
    private static let giftURLScheme = "loopix://gift/"
    private static let giftUnlockKey = "subscription.giftUnlock"

    /// Obfuscated HMAC key - reconstructed at runtime
    /// Key: "L00P1X-G1FT-S3CR3T-K3Y-2024" XOR'd with rotating mask
    private static let keyComponents: [[UInt8]] = [
        [0x78, 0x5c, 0x5c, 0x64, 0x55, 0x78, 0x2d], // Part 1
        [0x73, 0x55, 0x70, 0x64, 0x2d],             // Part 2
        [0x67, 0x5f, 0x71, 0x62, 0x5f, 0x64, 0x2d], // Part 3
        [0x77, 0x5f, 0x69, 0x2d],                   // Part 4
        [0x5e, 0x5c, 0x5e, 0x58]                    // Part 5
    ]
    private static let keyMask: UInt8 = 0x1C

    private static var hmacKey: SymmetricKey {
        var keyBytes: [UInt8] = []
        for part in keyComponents {
            for byte in part {
                keyBytes.append(byte ^ keyMask)
            }
        }
        return SymmetricKey(data: keyBytes)
    }

    // MARK: - Admin Access

    private static let adminUnlockKey = "subscription.adminUnlock"
    /// Admin password - obfuscated ("pamir" XOR 0x10)
    private static let adminPassComponents: [UInt8] = [0x60, 0x71, 0x7d, 0x79, 0x62]
    private static var adminPassword: String {
        String(adminPassComponents.map { Character(UnicodeScalar($0 ^ 0x10)) })
    }

    // MARK: - Published State

    /// Whether user has active Pro subscription (paid or gift)
    @Published private(set) var isPro: Bool = false

    /// Whether Pro is from gift code (also grants admin access)
    @Published private(set) var isGiftUnlock: Bool = false

    /// Whether admin session is active (password verified)
    @Published private(set) var isAdminSessionActive: Bool = false

    /// Available products
    @Published private(set) var products: [Product] = []

    /// Loading state
    @Published private(set) var isLoading: Bool = false

    // MARK: - Private

    private var updateListenerTask: Task<Void, Error>?
    private let productIDs = SubscriptionProduct.allCases.map { $0.rawValue }

    // MARK: - Initialization

    private init() {
        // Check for gift unlock first
        isGiftUnlock = UserDefaults.standard.bool(forKey: Self.giftUnlockKey)
        if isGiftUnlock {
            isPro = true
        }

        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        // Load initial subscription status
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods

    /// Load available products from App Store
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    /// Purchase the yearly Pro subscription
    func purchase() async throws {
        guard let product = products.first(where: { $0.id == SubscriptionProduct.yearlyPro.rawValue }) else {
            throw SubscriptionError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // Check if transaction is verified
            let transaction = try checkVerified(verification)

            // Update subscription status
            await updateSubscriptionStatus()

            // Finish the transaction
            await transaction.finish()

            // Track purchase
            Analytics.shared.trackEvent(
                category: .subscription,
                action: .purchase,
                name: "pro_yearly"
            )

        case .userCancelled:
            throw SubscriptionError.userCancelled

        case .pending:
            // Transaction is pending (e.g., Ask to Buy)
            break

        @unknown default:
            throw SubscriptionError.unknown
        }
    }

    /// Restore previous purchases
    func restore() async throws {
        // Sync with App Store
        try await AppStore.sync()

        // Update subscription status
        await updateSubscriptionStatus()

        if !isPro {
            throw SubscriptionError.verificationFailed
        }

        // Track restore
        Analytics.shared.trackEvent(
            category: .subscription,
            action: .restore,
            name: isPro ? "success" : "no_subscription"
        )
    }

    /// Update subscription status from current entitlements
    func updateSubscriptionStatus() async {
        // Check gift unlock first
        isGiftUnlock = UserDefaults.standard.bool(forKey: Self.giftUnlockKey)
        if isGiftUnlock {
            isPro = true
            UserDefaults.standard.set(true, forKey: "subscription.isPro")
            return
        }

        var hasActiveSubscription = false

        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if this is our Pro subscription
                if transaction.productID == SubscriptionProduct.yearlyPro.rawValue {
                    hasActiveSubscription = true
                    break
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }

        isPro = hasActiveSubscription

        // Persist locally for quick access
        UserDefaults.standard.set(isPro, forKey: "subscription.isPro")
    }

    // MARK: - Gift Code Methods

    /// Validate and apply gift code from QR scan
    /// Format: loopix://gift/XXXXXX-YYYYYYYY (code-signature)
    /// - Parameter scannedValue: The scanned QR code string (URL or raw code)
    /// - Returns: true if gift was successfully applied
    @discardableResult
    func applyGiftCode(_ scannedValue: String) -> Bool {
        // Extract code from URL if needed
        let payload: String
        if scannedValue.hasPrefix(Self.giftURLScheme) {
            payload = String(scannedValue.dropFirst(Self.giftURLScheme.count))
        } else if scannedValue.hasPrefix("filmbox://gift/") {
            // Legacy support
            payload = String(scannedValue.dropFirst("filmbox://gift/".count))
        } else {
            payload = scannedValue
        }

        // Parse code and signature
        let parts = payload.split(separator: "-")
        guard parts.count >= 2 else { return false }

        // Last part is signature, rest is the code
        let signatureHex = String(parts.last!)
        let code = parts.dropLast().joined(separator: "-")

        // Validate HMAC signature
        guard Self.validateSignature(code: code, signature: signatureHex) else {
            return false
        }

        // Apply gift unlock
        UserDefaults.standard.set(true, forKey: Self.giftUnlockKey)
        isGiftUnlock = true
        isPro = true
        UserDefaults.standard.set(true, forKey: "subscription.isPro")

        // Track gift redemption
        Analytics.shared.trackEvent(
            category: .subscription,
            action: .purchase,
            name: "gift_code"
        )

        return true
    }

    /// Validate HMAC signature
    private static func validateSignature(code: String, signature: String) -> Bool {
        let hmac = HMAC<SHA256>.authenticationCode(
            for: Data(code.utf8),
            using: hmacKey
        )
        let expectedSignature = hmac.prefix(4).map { String(format: "%02x", $0) }.joined()
        return signature.lowercased() == expectedSignature.lowercased()
    }

    /// Generate a new signed gift code (private - use generateGiftCodeIfAuthorized)
    private static func generateGiftCode(identifier: String? = nil) -> String {
        let code = identifier ?? generateRandomCode()
        let hmac = HMAC<SHA256>.authenticationCode(
            for: Data(code.utf8),
            using: hmacKey
        )
        let signature = hmac.prefix(4).map { String(format: "%02x", $0) }.joined()
        return "\(giftURLScheme)\(code)-\(signature)"
    }

    /// Generate random alphanumeric code
    private static func generateRandomCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // No ambiguous chars (0/O, 1/I/L)
        let length = 8
        return String((0..<length).map { _ in chars.randomElement()! })
    }

    /// Remove gift unlock (for testing)
    func removeGiftUnlock() {
        UserDefaults.standard.set(false, forKey: Self.giftUnlockKey)
        isGiftUnlock = false
        isAdminSessionActive = false
        Task {
            await updateSubscriptionStatus()
        }
    }

    // MARK: - Admin Session

    /// Check if user has admin access (gift unlock grants admin rights)
    var hasAdminAccess: Bool {
        isGiftUnlock
    }

    /// Verify admin password and activate session
    /// - Returns: true if password is correct
    @discardableResult
    func verifyAdminPassword(_ password: String) -> Bool {
        guard hasAdminAccess else { return false }
        let isValid = password == Self.adminPassword
        if isValid {
            isAdminSessionActive = true
        }
        return isValid
    }

    /// End admin session
    func endAdminSession() {
        isAdminSessionActive = false
    }

    /// Get a new gift QR code URL string (requires active admin session)
    static func generateGiftCodeIfAuthorized() -> String? {
        guard shared.isAdminSessionActive else { return nil }
        return generateGiftCode()
    }

    /// Bootstrap code for initial admin access (print to console in DEBUG)
    /// Call via lldb: `po SubscriptionManager.printBootstrapCode()`
    static func printBootstrapCode() -> String {
        let code = generateGiftCode(identifier: "ADMIN-BOOTSTRAP")
        print("🎁 Bootstrap gift code: \(code)")
        return code
    }

    /// Get cached Pro status (synchronous)
    var cachedIsPro: Bool {
        UserDefaults.standard.bool(forKey: "subscription.isPro")
    }

    // MARK: - Private Methods

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    await self?.updateSubscriptionStatus()
                    await transaction?.finish()
                } catch {
                    print("Transaction update failed: \(error)")
                }
            }
        }
    }

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Convenience Extension for SwiftUI

@available(iOS 17.0, *)
extension View {
    /// Show paywall if user is not Pro
    func requiresPro(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        self.fullScreenCover(isPresented: isPresented, onDismiss: onDismiss) {
            PaywallView()
        }
    }
}
