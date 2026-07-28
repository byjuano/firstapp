import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var libraryStore: FrameLibraryStore
    @State private var isShowingPicker = false

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.void.ignoresSafeArea()

                if libraryStore.savedFrames.isEmpty {
                    ContentUnavailableView {
                        Label("Todavía no hay fotos", systemImage: "photo.on.rectangle.angled")
                    } description: {
                        Text("Elige una foto para armar la primera.")
                    } actions: {
                        Button("Nueva foto") { isShowingPicker = true }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.ink)
                    }
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
                Theme.panelRaised
            }
        }
        .task {
            image = UIImage(contentsOfFile: url.path)
        }
    }
}

#Preview {
    LibraryView().environmentObject(FrameLibraryStore())
}
