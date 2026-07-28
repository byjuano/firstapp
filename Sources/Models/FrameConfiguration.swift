import Foundation

/// Qué datos EXIF se muestran en el marco. Los básicos están en el plan gratis;
/// fecha/ubicación y nombre o logo del fotógrafo requieren Pro.
struct VisibleFields: Codable, Equatable {
    var iso = true
    var aperture = true
    var shutterSpeed = true
    var focalLength = true
    var cameraAndLens = true
    var dateTimeAndLocation = false
    var photographerCredit = false
}

/// Posición del marco en el eje claro-oscuro. 0 = marco más claro, 1 = marco más oscuro.
/// El plan gratis solo permite los extremos (0 o 1); Pro habilita cualquier valor intermedio.
struct FrameColor: Codable, Equatable {
    var position: Double = 0.0

    static let light = FrameColor(position: 0.0)
    static let dark = FrameColor(position: 1.0)

    /// Ajusta la posición al extremo más cercano, para cuando el usuario no tiene Pro.
    func clampedToFreeTier() -> FrameColor {
        FrameColor(position: position < 0.5 ? 0.0 : 1.0)
    }
}

/// Todo lo necesario para renderizar un frame: la elección de diseño, formato,
/// personalización de marco y qué campos mostrar.
struct FrameConfiguration: Codable, Equatable {
    var layout: FrameLayout = .linea
    var format: ExportFormat = .feed
    var color: FrameColor = .light
    /// 0 = margen mínimo, 1 = margen máximo. Fijo en el plan gratis (ver `FrameSizeSlider`).
    var sizeFraction: Double = 0.3
    var visibleFields = VisibleFields()
    var photographerName: String = ""
    var showPhotographerCredit = false

    static let defaultFreeSize: Double = 0.3
}
