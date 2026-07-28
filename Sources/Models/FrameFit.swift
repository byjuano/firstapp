import Foundation

/// Cómo entra la foto en el lienzo del formato elegido.
///
/// Ambos modos están en el plan gratis a propósito: cobrar por que una foto
/// apaisada no se destruya en Stories haría que el plan gratis se sienta
/// defectuoso en vez de limitado.
enum FrameFit: String, CaseIterable, Identifiable, Codable {
    /// La foto llena el lienzo y se recorta lo que sobra.
    case recortar
    /// La foto entra entera y se agregan bandas negras alrededor.
    case fotoCompleta

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .recortar: return "Recortar"
        case .fotoCompleta: return "Foto completa"
        }
    }
}
