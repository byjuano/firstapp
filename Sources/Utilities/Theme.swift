import SwiftUI

/// Tokens de marca de Aperio: los mismos definidos en el spec de producto
/// (papel cálido / tinta cerca del negro / acento burdeos), con variante para modo oscuro.
enum Theme {
    static let paper = Color("Paper")
    static let paperRaised = Color("PaperRaised")
    static let ink = Color("Ink")
    static let inkSoft = Color("InkSoft")
    static let accent = Color("Accent")

    enum Font {
        /// New York (el serif del sistema de Apple), para títulos con carácter editorial.
        static func display(_ size: CGFloat, weight: SwiftUI.Font.Weight = .medium) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .serif)
        }

        /// SF Mono (el monospace del sistema), para datos técnicos y etiquetas.
        static func mono(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .monospaced)
        }
    }
}
