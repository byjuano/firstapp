import SwiftUI

/// Tokens de marca de Aperio.
///
/// La app está comprometida con un solo modo, oscuro: no se adapta al tema del
/// sistema. Es una decisión de identidad, no un descuido. Una foto se juzga
/// mejor sobre negro, y el fondo claro competía con la imagen.
///
/// El ámbar está reservado para lo que pertenece al plan Pro. Al no usarlo en
/// ningún otro lado, el usuario aprende de un vistazo qué es de pago sin tener
/// que leer etiquetas.
enum Theme {
    static let void = Color(rgb: 0x000000)
    static let panel = Color(rgb: 0x0A0A0A)
    static let panelRaised = Color(rgb: 0x111111)
    static let hairline = Color(rgb: 0x262626)
    static let ink = Color(rgb: 0xF5F5F2)
    static let inkDim = Color(rgb: 0x6B6B6E)
    static let inkFaint = Color(rgb: 0x3A3A3C)
    static let accent = Color(rgb: 0xC9A961)
    static let accentDim = Color(rgb: 0x4A3F26)

    enum Font {
        /// New York, el serif del sistema, para títulos con carácter editorial.
        static func display(_ size: CGFloat, weight: SwiftUI.Font.Weight = .medium) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .serif)
        }

        /// SF Mono, para todo dato técnico: es como los muestra una cámara.
        static func mono(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .monospaced)
        }
    }
}

extension Color {
    init(rgb: UInt32) {
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }

    /// Los mismos tokens que `Theme`, para el render final en Core Graphics.
    enum Aperio {
        static let void = UIColor(rgb: 0x000000)
        static let ink = UIColor(rgb: 0xF5F5F2)
        static let inkDim = UIColor(rgb: 0x9A9A9E)
        static let accent = UIColor(rgb: 0xC9A961)
    }
}
