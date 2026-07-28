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
                            Button {
                                purchase(productID: SubscriptionStore.yearlyProductID)
                            } label: {
                                planRow(title: "Anual", price: "$29.99/año", detail: "equivale a $2.50/mes")
                            }
                            Button {
                                purchase(productID: SubscriptionStore.monthlyProductID)
                            } label: {
                                planRow(title: "Mensual", price: "$4.99/mes", detail: nil)
                            }
                        }
                        .padding(.horizontal)
                        .disabled(isPurchasing)
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
