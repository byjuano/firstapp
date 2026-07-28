import Foundation

/// Estado de la suscripción Pro. La integración real con StoreKit 2 (productos,
/// compra, restauración, verificación de transacción) queda como siguiente paso;
/// esto deja el resto de la app (paywall, gating de controles) lista para conectarla.
@MainActor
final class SubscriptionStore: ObservableObject {
    @Published private(set) var isPro: Bool = false

    static let monthlyProductID = "com.aperio.app.pro.monthly"
    static let yearlyProductID = "com.aperio.app.pro.yearly"

    func purchase(productID: String) async throws {
        // TODO: StoreKit 2 — Product.products(for:), purchase(), verificación de transacción.
        isPro = true
    }

    func restorePurchases() async throws {
        // TODO: StoreKit 2 — AppStore.sync() y recorrer Transaction.currentEntitlements.
    }
}
