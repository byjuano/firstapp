import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @State private var isPurchasing = false

    private let benefits = [
        "Color y tamaño de marco personalizables",
        "Fecha, hora y ubicación en el frame",
        "Nombre o logo del fotógrafo",
        "Sin marca de agua de Aperio",
        "Lote ilimitado",
        "Sincronización con iCloud",
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.paper.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 6) {
                            Text("Aperio Pro")
                                .font(Theme.Font.display(28))
                                .italic()
                            Text("Personalización completa del marco")
                                .font(.subheadline)
                                .foregroundStyle(Theme.inkSoft)
                        }
                        .padding(.top, 16)

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(benefits, id: \.self) { benefit in
                                Label(benefit, systemImage: "checkmark")
                                    .font(.subheadline)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.paperRaised, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                        VStack(spacing: 12) {
                            if subscriptionStore.products.isEmpty {
                                Text("No se pudieron cargar los planes. Revisa la configuración de StoreKit en el esquema de Xcode.")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.inkSoft)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            } else {
                                ForEach(subscriptionStore.products) { product in
                                    Button {
                                        purchase(productID: product.id)
                                    } label: {
                                        planRow(
                                            title: product.displayName,
                                            price: product.displayPrice,
                                            detail: product.subscription?.subscriptionPeriod.aperioDetailLabel
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .disabled(isPurchasing)
                        .task { await subscriptionStore.loadProducts() }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .tint(Theme.accent)
    }

    private func planRow(title: String, price: String, detail: String?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(Theme.inkSoft)
                }
            }
            Spacer()
            Text(price).font(.headline)
        }
        .padding()
        .foregroundStyle(Theme.ink)
        .background(Theme.paperRaised, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.accent.opacity(0.4)))
    }

    private func purchase(productID: String) {
        isPurchasing = true
        Task {
            defer { isPurchasing = false }
            try? await subscriptionStore.purchase(productID: productID)
            await MainActor.run { dismiss() }
        }
    }
}

#Preview {
    PaywallView().environmentObject(SubscriptionStore())
}

private extension Product.SubscriptionPeriod {
    var aperioDetailLabel: String? {
        switch unit {
        case .month where value == 1: return "por mes"
        case .year where value == 1: return "por año"
        default: return nil
        }
    }
}
