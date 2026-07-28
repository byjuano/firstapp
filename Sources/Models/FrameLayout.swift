import Foundation

/// Los 3 diseños del v1, todos incluidos en el plan gratis.
///
/// Los tres parten de la misma idea: los datos viven sobre la imagen, no
/// alrededor de ella. No hay marco, así que no hay color ni grosor de marco
/// que configurar.
enum FrameLayout: String, CaseIterable, Identifiable, Codable {
    /// Brackets de esquina y una lectura técnica, como el punto de foco de un visor.
    case visor
    /// Franja sólida con los números en monoespaciado, como una claqueta de rodaje.
    case claqueta
    /// Texto centrado, como los créditos finales de una película.
    case creditos

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .visor: return "Visor"
        case .claqueta: return "Claqueta"
        case .creditos: return "Créditos"
        }
    }

    var summary: String {
        switch self {
        case .visor: return "Brackets de esquina y lectura técnica."
        case .claqueta: return "Franja con los datos, densa y legible."
        case .creditos: return "Texto centrado, sobrio."
        }
    }
}
