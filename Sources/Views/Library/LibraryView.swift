import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var libraryStore: FrameLibraryStore
    @State private var isShowingPicker = false

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.paper.ignoresSafeArea()

                if libraryStore.savedFrames.isEmpty {
                    ContentUnavailableFallback(
                        title: "Todavía no hay frames",
                        message: "Elige una foto para armar el primero.",
                        actionTitle: "Nuevo frame",
                        action: { isShowingPicker = true }
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(libraryStore.savedFrames) { frame in
                                SavedFrameThumbnail(frame: frame)
                            }
                        }
                        .padding()
                    }
                }
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

private struct SavedFrameThumbnail: View {
    @EnvironmentObject private var libraryStore: FrameLibraryStore
    let frame: SavedFrame

    var body: some View {
        AsyncFileImage(url: libraryStore.thumbnailURL(for: frame))
            .aspectRatio(frame.configuration.format.aspectRatio, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contextMenu {
                Button("Eliminar", role: .destructive) {
                    libraryStore.delete(frame)
                }
            }
    }
}

/// Carga una imagen desde disco de forma perezosa, sin depender de `AsyncImage`
/// (pensado para URLs remotas) para leer los thumbnails guardados localmente.
private struct AsyncFileImage: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable()
            } else {
                Theme.paperRaised
            }
        }
        .task {
            image = UIImage(contentsOfFile: url.path)
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
    LibraryView().environmentObject(FrameLibraryStore())
}
