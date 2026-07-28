import Foundation

/// Los 3 diseños de marco disponibles en el v1, todos incluidos en el plan gratis.
enum FrameLayout: String, CaseIterable, Identifiable, Codable {
    case linea
    case ficha
    case esquina

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .linea: return "Línea"
        case .ficha: return "Ficha"
        case .esquina: return "Esquina"
        }
    }

    var summary: String {
        switch self {
        case .linea:
            return "Margen fino y una línea de datos debajo de la foto."
        case .ficha:
            return "Franja inferior con los datos organizados en grilla."
        case .esquina:
            return "Sin marco: los datos se apoyan sobre la foto, en una esquina."
        }
    }
}
