import Foundation
import StoreKit

enum StoreProduct {
    /// One-time, lifetime unlock. Non-consumable.
    static let lifetime = "loopix_once"

    /// Legacy subscription products. No longer sold, but anyone who ever bought
    /// one keeps Pro forever — we still honor their entitlement.
    static let legacyIDs: Set<String> = ["20002", "20004"]

    /// Every product id that grants Pro access.
    static var proGrantingIDs: Set<String> { legacyIDs.union([lifetime]) }
}

enum SubscriptionError: LocalizedError {
    case productNotFound
    case purchaseFailed
    case verificationFailed
    case userCancelled
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound: return "Product not found"
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

    /// Persisted Pro flag. Kept under the original key so users who were already
    /// Pro on a previous (subscription) build stay Pro after updating.
    private static let proKey = "subscription.isPro"

    private(set) var isPro: Bool = false
    private(set) var products: [Product] = []
    private(set) var isLoading: Bool = false

    private let updateListenerTask: Task<Void, Never>

    private init() {
        // Latch: once Pro, always Pro. Read the persisted flag first.
        isPro = UserDefaults.standard.bool(forKey: Self.proKey)

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
            await refreshEntitlements()
        }
    }

    deinit {
        updateListenerTask.cancel()
    }

    // MARK: - Public

    var lifetimeProduct: Product? {
        products.first { $0.id == StoreProduct.lifetime }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: [StoreProduct.lifetime])
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ productID: String = StoreProduct.lifetime) async throws {
        if products.isEmpty {
            await loadProducts()
        }
        guard let product = products.first(where: { $0.id == productID }) else {
            throw SubscriptionError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try verifyResult(verification)
            if StoreProduct.proGrantingIDs.contains(transaction.productID) {
                grantPro()
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
        await refreshEntitlements()
        if !isPro {
            throw SubscriptionError.verificationFailed
        }
    }

    /// Launch / refresh check. Purely additive: it only ever *grants* Pro.
    /// A missing or empty entitlement set (cold launch, no network, StoreKit not
    /// ready) must never lock anyone out, so we never flip Pro off here.
    func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verifyResult(result),
                  StoreProduct.proGrantingIDs.contains(transaction.productID) else { continue }
            if transaction.revocationDate != nil { continue }
            if let expiry = transaction.expirationDate, expiry < Date() { continue }

            grantPro()
            return
        }
    }

    /// Reacts to a single transaction update. Also purely additive — see the
    /// product brief: once a user has paid, Pro is permanent and is never
    /// revoked (not on refund, not on expiry).
    private func handle(_ transaction: Transaction) async {
        guard StoreProduct.proGrantingIDs.contains(transaction.productID) else { return }
        if transaction.revocationDate != nil { return }
        if let expiry = transaction.expirationDate, expiry < Date() { return }
        grantPro()
    }

    /// One-way latch. Persists immediately and is never undone.
    private func grantPro() {
        guard !isPro else { return }
        isPro = true
        UserDefaults.standard.set(true, forKey: Self.proKey)
    }

    #if DEBUG
    /// Debug-only override of the Pro flag. Bypasses the latch so the dev menu
    /// can flip premium on/off freely. Never compiled into release builds.
    func debugSetPro(_ value: Bool) {
        isPro = value
        UserDefaults.standard.set(value, forKey: Self.proKey)
    }

    /// Debug-only: clear the persisted latch so the purchase flow can be retested.
    func debugReset() {
        isPro = false
        UserDefaults.standard.removeObject(forKey: Self.proKey)
    }
    #endif
}
