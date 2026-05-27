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
                    await SubscriptionManager.shared.handle(transaction)
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
                setPro(true)
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

    /// Launch / refresh check. Deliberately *optimistic*: it only ever upgrades to Pro.
    /// Empty or unavailable entitlements on a cold launch (e.g. no network, StoreKit not
    /// ready) must NOT lock a paying user out — so we never flip Pro off here. Genuine
    /// loss of access (refund, revocation, expiry) is handled by `handle(_:)` on the
    /// `Transaction.updates` stream, which is the only place that downgrades.
    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verifyResult(result),
                  productIDs.contains(transaction.productID) else { continue }
            // Ignore entitlements that aren't actually valid right now.
            if transaction.revocationDate != nil { continue }
            if let expiry = transaction.expirationDate, expiry < Date() { continue }

            setPro(true)
            return
        }
    }

    /// Reacts to a single transaction update. This is where access is granted *or*
    /// revoked, because a transaction carries an authoritative signal (revocation/expiry).
    private func handle(_ transaction: Transaction) async {
        guard productIDs.contains(transaction.productID) else { return }

        if transaction.revocationDate != nil {
            setPro(false)
        } else if let expiry = transaction.expirationDate, expiry < Date() {
            setPro(false)
        } else {
            setPro(true)
        }
    }

    private func setPro(_ value: Bool) {
        isPro = value
        UserDefaults.standard.set(value, forKey: "subscription.isPro")
    }
}
