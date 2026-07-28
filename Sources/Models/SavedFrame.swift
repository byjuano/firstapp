import Foundation

/// Un frame ya exportado, guardado en la biblioteca local del dispositivo.
struct SavedFrame: Codable, Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let configuration: FrameConfiguration
    let exif: ExifData
    /// Nombre del archivo del thumbnail dentro de `FrameLibraryStore.thumbnailsDirectory`.
    let thumbnailFilename: String

    init(configuration: FrameConfiguration, exif: ExifData, thumbnailFilename: String) {
        self.id = UUID()
        self.createdAt = Date()
        self.configuration = configuration
        self.exif = exif
        self.thumbnailFilename = thumbnailFilename
    }
}
