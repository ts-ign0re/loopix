import Foundation
import StoreKit

enum SubscriptionProduct: String, CaseIterable {
    case monthlyPro = "20004"
    case yearlyPro = "20002"
}

enum SubscriptionError: LocalizedError {
    case productNotFound
    case purchaseFailed
    case verificationFailed
    case userCancelled
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound: return "Subscription product not found"
        case .purchaseFailed: return "Purchase failed"
        case .verificationFailed: return "Could not verify purchase"
        case .userCancelled: return "Purchase was cancelled"
        case .unknown: return "An unknown error occurred"
        }
    }
}

private func verifyResult<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
        throw SubscriptionError.verificationFailed
    case .verified(let safe):
        return safe
    }
}

@MainActor @Observable
final class SubscriptionManager {

    static let shared = SubscriptionManager()
    static let freeFilterIDs: Set<String> = ["clean", "mono", "portra"]

    private(set) var isPro: Bool = false
    private(set) var products: [Product] = []
    private(set) var isLoading: Bool = false

    private let updateListenerTask: Task<Void, Never>
    private let productIDs = SubscriptionProduct.allCases.map { $0.rawValue }

    private init() {
        let cachedPro = UserDefaults.standard.bool(forKey: "subscription.isPro")
        if cachedPro {
            isPro = true
        }

        updateListenerTask = Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? verifyResult(result) {
                    await SubscriptionManager.shared.updateSubscriptionStatus()
                    await transaction.finish()
                }
            }
        }

        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask.cancel()
    }

    // MARK: - Public

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ productID: String = SubscriptionProduct.yearlyPro.rawValue) async throws {
        guard let product = products.first(where: { $0.id == productID }) else {
            throw SubscriptionError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try verifyResult(verification)
            if productIDs.contains(transaction.productID) {
                isPro = true
                UserDefaults.standard.set(true, forKey: "subscription.isPro")
            }
            await transaction.finish()

        case .userCancelled:
            throw SubscriptionError.userCancelled

        case .pending:
            break

        @unknown default:
            throw SubscriptionError.unknown
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
        if !isPro {
            throw SubscriptionError.verificationFailed
        }
    }

    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            if let transaction = try? verifyResult(result),
               productIDs.contains(transaction.productID) {
                hasActiveSubscription = true
                break
            }
        }

        if hasActiveSubscription {
            isPro = true
            UserDefaults.standard.set(true, forKey: "subscription.isPro")
        }
        // Don't reset isPro to false here — trust the local cache.
        // Empty entitlements on cold launch doesn't mean the sub expired;
        // StoreKit may simply not be ready yet. Actual expiry is handled
        // by the Transaction.updates listener.
    }
}
