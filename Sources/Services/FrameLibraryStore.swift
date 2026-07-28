import Foundation
import UIKit

/// Persiste la biblioteca de frames ya exportados: un índice en JSON más un
/// thumbnail JPEG por frame, ambos en el directorio de Documentos de la app.
@MainActor
final class FrameLibraryStore: ObservableObject {
    @Published private(set) var savedFrames: [SavedFrame] = []

    private let indexURL: URL
    let thumbnailsDirectory: URL

    init(fileManager: FileManager = .default) {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        thumbnailsDirectory = documents.appendingPathComponent("FrameThumbnails", isDirectory: true)
        indexURL = documents.appendingPathComponent("frame-library.json")

        try? fileManager.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
        savedFrames = Self.loadIndex(from: indexURL)
    }

    func save(image: UIImage, configuration: FrameConfiguration, exif: ExifData) {
        let filename = "\(UUID().uuidString).jpg"
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }

        let fileURL = thumbnailsDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            return
        }

        let entry = SavedFrame(configuration: configuration, exif: exif, thumbnailFilename: filename)
        savedFrames.insert(entry, at: 0)
        persistIndex()
    }

    func delete(_ frame: SavedFrame) {
        let fileURL = thumbnailsDirectory.appendingPathComponent(frame.thumbnailFilename)
        try? FileManager.default.removeItem(at: fileURL)
        savedFrames.removeAll { $0.id == frame.id }
        persistIndex()
    }

    func thumbnailURL(for frame: SavedFrame) -> URL {
        thumbnailsDirectory.appendingPathComponent(frame.thumbnailFilename)
    }

    private func persistIndex() {
        guard let data = try? JSONEncoder().encode(savedFrames) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }

    private static func loadIndex(from url: URL) -> [SavedFrame] {
        guard
            let data = try? Data(contentsOf: url),
            let frames = try? JSONDecoder().decode([SavedFrame].self, from: data)
        else { return [] }
        return frames
    }
}
