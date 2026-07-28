import CoreGraphics
import Foundation

/// Los 4 formatos de exportación del v1. Todos están disponibles en el plan gratis;
/// lo que cambia según el plan es la personalización del marco (ver `FrameConfiguration`).
enum ExportFormat: String, CaseIterable, Identifiable, Codable {
    case feed
    case vertical
    case horizontal
    case stories

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .feed: return "Feed"
        case .vertical: return "Vertical"
        case .horizontal: return "Horizontal"
        case .stories: return "Stories"
        }
    }

    var aspectRatioLabel: String {
        switch self {
        case .feed: return "1:1"
        case .vertical: return "4:5"
        case .horizontal: return "1.91:1"
        case .stories: return "9:16"
        }
    }

    /// Ancho / alto, usado para componer el lienzo final.
    var aspectRatio: CGFloat {
        switch self {
        case .feed: return 1.0
        case .vertical: return 4.0 / 5.0
        case .horizontal: return 1.91
        case .stories: return 9.0 / 16.0
        }
    }

    /// Ancho de exportación recomendado en píxeles; el alto se calcula con `aspectRatio`.
    var exportWidthPixels: CGFloat { 1080 }
}
