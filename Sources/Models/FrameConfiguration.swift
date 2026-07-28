import CoreGraphics
import Foundation

/// Qué datos se muestran. Los de la toma son gratis; la ubicación y la firma
/// del fotógrafo pertenecen a Pro.
struct VisibleFields: Codable, Equatable {
    var iso = true
    var aperture = true
    var shutterSpeed = true
    var focalLength = true
    var cameraAndLens = true
    var dateTimeAndLocation = false
    var photographerCredit = false
}

/// Color del texto de los datos. Reemplaza al viejo "color del marco": ahora que
/// no hay marco, lo que se puede teñir es la tipografía.
enum AccentTint: String, CaseIterable, Identifiable, Codable {
    case neutro
    case ambar
    case blanco

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .neutro: return "Neutro"
        case .ambar: return "Ámbar"
        case .blanco: return "Blanco"
        }
    }
}

/// Todo lo necesario para componer una imagen: plantilla, formato, encuadre,
/// qué datos se muestran y los ajustes de Pro.
struct FrameConfiguration: Codable, Equatable {
    var layout: FrameLayout = .visor
    var format: ExportFormat = .feed
    var fit: FrameFit = .recortar
    var visibleFields = VisibleFields()

    // Ajustes de Pro. Cuando el usuario no tiene suscripción se ignoran y se
    // usan los valores por defecto (ver `resolved(isPro:)`), en vez de
    // deshabilitar los controles en cada vista.
    var accent: AccentTint = .neutro
    /// Multiplicador del cuerpo del texto. 1.0 es el tamaño base de la plantilla.
    var textScale: Double = 1.0
    var photographerName: String = ""

    static let defaultTextScale: Double = 1.0

    /// El multiplicador como `CGFloat`, que es lo que esperan los cálculos de
    /// tamaño. Evita mezclar `Double` y `CGFloat` en cada multiplicación.
    var textScaleValue: CGFloat { CGFloat(textScale) }

    /// La configuración efectiva según el plan. Centralizar esto acá evita que
    /// la vista previa y el render final apliquen el gating de forma distinta.
    func resolved(isPro: Bool) -> FrameConfiguration {
        guard !isPro else { return self }
        var free = self
        free.accent = .neutro
        free.textScale = Self.defaultTextScale
        free.photographerName = ""
        free.visibleFields.dateTimeAndLocation = false
        free.visibleFields.photographerCredit = false
        return free
    }
}
