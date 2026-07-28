import SwiftUI
import UIKit

/// Tokens de marca de Aperio: los mismos definidos en el spec de producto
/// (papel cálido / tinta cerca del negro / acento burdeos), con variante para modo oscuro.
/// Se definen en código (no en el catálogo de assets) para no depender de que el
/// recurso quede correctamente incluido en el target al generar el proyecto.
enum Theme {
    static let paper = Color(light: (0xED, 0xEA, 0xE4), dark: (0x15, 0x12, 0x0E))
    static let paperRaised = Color(light: (0xF7, 0xF5, 0xF0), dark: (0x1E, 0x1A, 0x15))
    static let ink = Color(light: (0x1C, 0x18, 0x15), dark: (0xF1, 0xEC, 0xE3))
    static let inkSoft = Color(light: (0x5B, 0x56, 0x4E), dark: (0xB6, 0xAE, 0xA0))
    static let accent = Color(light: (0x7C, 0x2A, 0x34), dark: (0xE1, 0x7E, 0x86))

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

private extension Color {
    /// Un color dinámico claro/oscuro a partir de componentes RGB de 8 bits (0-255),
    /// sin pasar por el catálogo de assets.
    init(light: (UInt8, UInt8, UInt8), dark: (UInt8, UInt8, UInt8)) {
        let uiColor = UIColor { traits in
            let components = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat(components.0) / 255,
                green: CGFloat(components.1) / 255,
                blue: CGFloat(components.2) / 255,
                alpha: 1
            )
        }
        self.init(uiColor: uiColor)
    }
}
