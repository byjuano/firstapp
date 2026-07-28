import CoreGraphics

/// Dónde va la foto y dónde va la banda de datos, para un lienzo dado.
///
/// La vista previa (SwiftUI) y el render final (Core Graphics) consumen esta
/// misma estructura. Si cada una calculara su propio layout, lo que el usuario
/// ve y lo que exporta podrían dejar de coincidir sin que nadie lo note.
struct FrameGeometry {
    let canvas: CGSize
    /// Dónde se dibuja la foto. En modo recortar ocupa todo el lienzo.
    let photoRect: CGRect
    /// La banda inferior de datos. Vacía en modo recortar.
    let bandRect: CGRect

    var hasBand: Bool { bandRect.height > 0 }

    /// Un punto de escala relativo al ancho: 1 unidad = 1% del ancho del lienzo.
    ///
    /// Todos los tamaños de texto y espaciados se expresan en estas unidades,
    /// así la vista previa de 300pt y la exportación de 1080px producen
    /// exactamente la misma composición.
    var unit: CGFloat { canvas.width / 100 }

    /// En modo recortar los datos van sobre la foto y necesitan un degradado
    /// que garantice contraste. Con banda, el fondo ya es negro sólido y ese
    /// degradado deja de tener función.
    var needsScrim: Bool { !hasBand }

    /// El área donde se dibujan los datos: la banda si existe, o la franja
    /// inferior de la foto si no.
    var dataRect: CGRect {
        hasBand ? bandRect : CGRect(
            x: 0,
            y: canvas.height - canvas.height * 0.22,
            width: canvas.width,
            height: canvas.height * 0.22
        )
    }

    static func compute(
        canvas rawCanvas: CGSize,
        photoAspect rawPhotoAspect: CGFloat,
        configuration: FrameConfiguration
    ) -> FrameGeometry {
        // Los tamaños entrantes pueden ser 0 durante el primer pase de layout
        // de SwiftUI; sin este piso se propagan dimensiones negativas.
        let canvas = CGSize(
            width: max(rawCanvas.width, 1),
            height: max(rawCanvas.height, 1)
        )
        let photoAspect = rawPhotoAspect > 0 ? rawPhotoAspect : 1

        switch configuration.fit {
        case .recortar:
            return FrameGeometry(
                canvas: canvas,
                photoRect: CGRect(origin: .zero, size: canvas),
                bandRect: .zero
            )

        case .fotoCompleta:
            // Se reserva siempre una banda inferior, incluso cuando la foto
            // sobraría de ancho. Así los datos tienen un lugar fijo sea cual
            // sea la orientación de la foto, en vez de quedar sin banda
            // cuando el sobrante cae a los costados.
            let bandHeight = canvas.height * configuration.layout.bandHeightFraction
            let availableHeight = max(canvas.height - bandHeight, 1)

            let fittedWidth = min(canvas.width, availableHeight * photoAspect)
            let fittedHeight = max(fittedWidth / photoAspect, 1)

            let photoRect = CGRect(
                x: (canvas.width - fittedWidth) / 2,
                y: (availableHeight - fittedHeight) / 2,
                width: fittedWidth,
                height: fittedHeight
            )
            let bandRect = CGRect(
                x: 0,
                y: canvas.height - bandHeight,
                width: canvas.width,
                height: bandHeight
            )
            return FrameGeometry(canvas: canvas, photoRect: photoRect, bandRect: bandRect)
        }
    }
}

private extension FrameLayout {
    /// Cuánto alto pide cada plantilla para su banda. Claqueta necesita más
    /// porque apila etiqueta y valor en varias columnas.
    var bandHeightFraction: CGFloat {
        switch self {
        case .visor: return 0.16
        case .claqueta: return 0.20
        case .creditos: return 0.18
        }
    }
}
