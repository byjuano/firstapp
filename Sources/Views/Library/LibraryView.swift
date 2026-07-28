import SwiftUI

struct LibraryView: View {
    @State private var isShowingPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.paper.ignoresSafeArea()
                ContentUnavailableFallback(
                    title: "Todavía no hay frames",
                    message: "Elige una foto para armar el primero.",
                    actionTitle: "Nuevo frame",
                    action: { isShowingPicker = true }
                )
            }
            .navigationTitle("Aperio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingPicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingPicker) {
                PhotoPickerView()
            }
        }
    }
}

/// Estado vacío simple. `ContentUnavailableView` (iOS 17+) sería la opción nativa;
/// esta versión propia mantiene compatibilidad con el deploymentTarget 16.0 del proyecto.
private struct ContentUnavailableFallback: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 44))
                .foregroundStyle(Theme.inkSoft)
            Text(title)
                .font(Theme.Font.display(20))
                .italic()
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
                .tint(Theme.ink)
        }
        .foregroundStyle(Theme.ink)
    }
}

#Preview {
    LibraryView()
}
