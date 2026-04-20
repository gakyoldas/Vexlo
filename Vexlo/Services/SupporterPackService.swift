import Foundation
import StoreKit

enum SupporterPackPurchaseResult {
    case success
    case cancelled
    case pending
    case unavailable
    case failed
}

@MainActor
final class SupporterPackService {
    static let shared = SupporterPackService()

    enum ProductID {
        static let supporterPack = "com.northfall.vexlo.supporterpack"
    }

    var onStateChanged: (() -> Void)?

    private(set) var product: Product?
    private(set) var isOwned = false
    private(set) var isProductLoaded = false
    private var hasStarted = false
    private var updatesTask: Task<Void, Never>?

    private init() {}

    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        updatesTask = Task { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                await self.handle(result)
            }
        }
        Task {
            await refreshProducts()
            await refreshEntitlements()
        }
    }

    func refreshProducts() async {
        do {
            let products = try await Product.products(for: [ProductID.supporterPack])
            product = products.first
            isProductLoaded = product != nil
        } catch {
            product = nil
            isProductLoaded = false
        }
        onStateChanged?()
    }

    func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == ProductID.supporterPack {
                owned = transaction.revocationDate == nil
            }
        }
        isOwned = owned
        onStateChanged?()
    }

    func purchase() async -> SupporterPackPurchaseResult {
        guard let product else { return .unavailable }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return .failed }
                await transaction.finish()
                await refreshEntitlements()
                return .success
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed
            }
        } catch {
            return .failed
        }
    }

    func restore() async -> Bool {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            return true
        } catch {
            return false
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == ProductID.supporterPack {
            await transaction.finish()
            await refreshEntitlements()
        }
    }
}
