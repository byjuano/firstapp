import Foundation
import StoreKit

/// Estado real de la suscripción Pro usando StoreKit 2: carga los productos,
/// procesa la compra, escucha actualizaciones de transacciones y deriva `isPro`
/// de las entitlements vigentes (no de una bandera guardada a mano).
@MainActor
final class SubscriptionStore: ObservableObject {
    @Published private(set) var isPro = false
    @Published private(set) var products: [Product] = []
    @Published var purchaseError: String?

    static let monthlyProductID = "com.aperio.app.pro.monthly"
    static let yearlyProductID = "com.aperio.app.pro.yearly"
    private static let productIDs = [monthlyProductID, yearlyProductID]

    private var transactionListenerTask: Task<Void, Never>?

    init() {
        transactionListenerTask = listenForTransactionUpdates()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            purchaseError = "No se pudieron cargar los planes. Vuelve a intentarlo más tarde."
        }
    }

    func purchase(productID: String) async throws {
        guard let product = products.first(where: { $0.id == productID }) else {
            await loadProducts()
            guard let reloaded = products.first(where: { $0.id == productID }) else {
                throw StoreError.productNotFound
            }
            try await purchase(product: reloaded)
            return
        }
        try await purchase(product: product)
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    private func purchase(product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshEntitlements()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    private func refreshEntitlements() async {
        var hasEntitlement = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result), Self.productIDs.contains(transaction.productID) {
                hasEntitlement = true
            }
        }
        isPro = hasEntitlement
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                guard let transaction = try? await self.checkVerified(result) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: Error {
        case productNotFound
        case failedVerification
    }
}
