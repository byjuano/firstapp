import PhotosUI
import SwiftUI

struct PhotoPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection: PhotosPickerItem?
    @State private var loadedPhoto: LoadedPhoto?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.paper.ignoresSafeArea()

                PhotosPicker(selection: $selection, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 40))
                        Text("Elegir foto")
                            .font(.headline)
                    }
                    .foregroundStyle(Theme.ink)
                }

                if isLoading {
                    ProgressView("Leyendo EXIF…")
                }
            }
            .navigationTitle("Nueva foto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onChange(of: selection) { _, newValue in
                guard let newValue else { return }
                load(item: newValue)
            }
            .navigationDestination(item: $loadedPhoto) { photo in
                EditorView(photo: photo.image, exif: photo.exif)
            }
        }
    }

    private func load(item: PhotosPickerItem) {
        isLoading = true
        Task {
            defer { isLoading = false }
            guard
                let data = try? await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else { return }
            let exif = ExifReader.read(from: data)
            await MainActor.run {
                loadedPhoto = LoadedPhoto(image: image, exif: exif)
            }
        }
    }
}

private struct LoadedPhoto: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage
    let exif: ExifData

    static func == (lhs: LoadedPhoto, rhs: LoadedPhoto) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

#Preview {
    PhotoPickerView()
}
