//
//  SubscriptionManager.swift
//  FilmBox
//
//  StoreKit 2 subscription management
//

import Foundation
import StoreKit
import SwiftUI

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

    // MARK: - Published State

    /// Whether user has active Pro subscription
    @Published private(set) var isPro: Bool = false

    /// Available products
    @Published private(set) var products: [Product] = []

    /// Loading state
    @Published private(set) var isLoading: Bool = false

    // MARK: - Private

    private var updateListenerTask: Task<Void, Error>?
    private let productIDs = SubscriptionProduct.allCases.map { $0.rawValue }

    // MARK: - Initialization

    private init() {
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
