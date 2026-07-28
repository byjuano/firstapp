import CoreGraphics
import UIKit

/// Compone la imagen final que se comparte o se guarda.
///
/// Comparte `FrameGeometry` y `FrameContent` con la vista previa, así que el
/// layout y los textos no pueden divergir. Lo único propio de acá es el dibujo.
enum FrameRenderer {
    static func render(
        photo: UIImage,
        exif: ExifData,
        configuration rawConfiguration: FrameConfiguration,
        isPro: Bool
    ) -> UIImage {
        let configuration = rawConfiguration.resolved(isPro: isPro)
        let content = FrameContent(exif: exif, configuration: rawConfiguration, isPro: isPro)

        let width = configuration.format.exportWidthPixels
        let canvas = CGSize(width: width, height: width / configuration.format.aspectRatio)
        let geo = FrameGeometry.compute(
            canvas: canvas,
            photoAspect: photo.size.height > 0 ? photo.size.width / photo.size.height : 1,
            configuration: configuration
        )

        let renderer = UIGraphicsImageRenderer(size: canvas)
        return renderer.image { context in
            UIColor.Aperio.void.setFill()
            context.fill(CGRect(origin: .zero, size: canvas))

            photo.drawAspectFilled(in: geo.photoRect, context: context)

            if geo.needsScrim {
                drawScrim(geo: geo, context: context)
            }

            switch configuration.layout {
            case .visor: drawVisor(geo: geo, content: content, configuration: configuration, context: context)
            case .claqueta: drawClaqueta(geo: geo, content: content, configuration: configuration, context: context)
            case .creditos: drawCreditos(geo: geo, content: content, configuration: configuration, context: context)
            }
        }
    }

    // MARK: - Fondo

    private static func drawScrim(geo: FrameGeometry, context: UIGraphicsImageRendererContext) {
        let height = geo.canvas.height * 0.36
        let rect = CGRect(x: 0, y: geo.canvas.height - height, width: geo.canvas.width, height: height)
        let colors = [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.withAlphaComponent(0.82).cgColor]
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: [0, 1]
        ) else { return }

        context.cgContext.saveGState()
        context.cgContext.clip(to: rect)
        context.cgContext.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: rect.minY),
            end: CGPoint(x: 0, y: rect.maxY),
            options: []
        )
        context.cgContext.restoreGState()
    }

    // MARK: - Visor

    private static func drawVisor(
        geo: FrameGeometry,
        content: FrameContent,
        configuration: FrameConfiguration,
        context: UIGraphicsImageRendererContext
    ) {
        let inset = geo.photoRect.width * 0.06
        let bracketRect = geo.photoRect.insetBy(dx: inset, dy: inset)
        guard bracketRect.width > 0, bracketRect.height > 0 else { return }

        let length = geo.unit * 3.5
        let lineWidth = max(geo.unit * 0.18, 1)
        context.cgContext.setStrokeColor(UIColor.Aperio.ink.withAlphaComponent(0.9).cgColor)
        context.cgContext.setLineWidth(lineWidth)

        let corners: [[CGPoint]] = [
            [CGPoint(x: bracketRect.minX, y: bracketRect.minY + length),
             CGPoint(x: bracketRect.minX, y: bracketRect.minY),
             CGPoint(x: bracketRect.minX + length, y: bracketRect.minY)],
            [CGPoint(x: bracketRect.maxX - length, y: bracketRect.minY),
             CGPoint(x: bracketRect.maxX, y: bracketRect.minY),
             CGPoint(x: bracketRect.maxX, y: bracketRect.minY + length)],
            [CGPoint(x: bracketRect.maxX, y: bracketRect.maxY - length),
             CGPoint(x: bracketRect.maxX, y: bracketRect.maxY),
             CGPoint(x: bracketRect.maxX - length, y: bracketRect.maxY)],
            [CGPoint(x: bracketRect.minX + length, y: bracketRect.maxY),
             CGPoint(x: bracketRect.minX, y: bracketRect.maxY),
             CGPoint(x: bracketRect.minX, y: bracketRect.maxY - length)],
        ]
        for corner in corners {
            context.cgContext.addLines(between: corner)
        }
        context.cgContext.strokePath()

        var cursor = geo.dataRect.midY - geo.unit * 4
        let left = geo.unit * 8
        let maxWidth = geo.canvas.width * 0.72

        if let camera = content.cameraLine {
            let font = UIFont.monospacedSystemFont(ofSize: geo.unit * 2.4 * configuration.textScaleValue, weight: .regular)
            draw(camera.uppercased(), at: CGPoint(x: left, y: cursor), width: maxWidth, font: font, color: UIColor.Aperio.ink, alignment: .left)
            cursor += font.lineHeight + geo.unit * 0.6
        }

        let settingsFont = UIFont.monospacedSystemFont(ofSize: geo.unit * 2.1 * configuration.textScaleValue, weight: .regular)
        draw(content.settingsLine, at: CGPoint(x: left, y: cursor), width: maxWidth, font: settingsFont, color: dataColor(configuration), alignment: .left)
        cursor += settingsFont.lineHeight + geo.unit * 0.6

        if let credit = content.credit {
            let font = serifFont(ofSize: geo.unit * 2.2 * configuration.textScaleValue, italic: true)
            draw(credit, at: CGPoint(x: left, y: cursor), width: maxWidth, font: font, color: UIColor.Aperio.ink.withAlphaComponent(0.85), alignment: .left)
        }

        if content.showWatermark {
            // Va a la derecha, del lado opuesto a la lectura técnica, para que
            // las dos esquinas del bloque de datos queden balanceadas.
            let font = UIFont.monospacedSystemFont(ofSize: geo.unit * 1.5, weight: .regular)
            draw(
                "Aperio",
                at: CGPoint(x: left, y: geo.dataRect.midY - geo.unit * 1),
                width: geo.canvas.width - left * 2,
                font: font,
                color: UIColor.Aperio.ink.withAlphaComponent(0.5),
                alignment: .right
            )
        }
    }

    // MARK: - Claqueta

    private static func drawClaqueta(
        geo: FrameGeometry,
        content: FrameContent,
        configuration: FrameConfiguration,
        context: UIGraphicsImageRendererContext
    ) {
        let bar = geo.hasBand
            ? geo.bandRect
            : CGRect(
                x: 0,
                y: geo.canvas.height - geo.canvas.height * 0.20,
                width: geo.canvas.width,
                height: geo.canvas.height * 0.20
            )

        // Con banda el fondo ya es negro sólido; sin banda hace falta opacar la foto.
        if !geo.hasBand {
            UIColor.black.withAlphaComponent(0.82).setFill()
            context.fill(bar)
        } else {
            UIColor.Aperio.void.setFill()
            context.fill(bar)
        }

        UIColor.Aperio.accent.setFill()
        context.fill(CGRect(x: bar.minX, y: bar.minY, width: bar.width, height: max(geo.unit * 0.4, 1)))

        let padding = geo.unit * 7
        let labelFont = UIFont.monospacedSystemFont(ofSize: geo.unit * 1.5 * configuration.textScaleValue, weight: .regular)
        let valueFont = UIFont.monospacedSystemFont(ofSize: geo.unit * 2.3 * configuration.textScaleValue, weight: .semibold)
        let blockHeight = labelFont.lineHeight + valueFont.lineHeight + geo.unit * 0.4
        let top = bar.midY - blockHeight / 2

        var x = bar.minX + padding
        let columnWidth = max((bar.width - padding * 2) / CGFloat(max(content.stats.count, 1)) - geo.unit * 2, geo.unit * 10)

        for stat in content.stats {
            draw(stat.label, at: CGPoint(x: x, y: top), width: columnWidth, font: labelFont, color: UIColor.Aperio.accent, alignment: .left)
            draw(stat.value, at: CGPoint(x: x, y: top + labelFont.lineHeight + geo.unit * 0.4), width: columnWidth, font: valueFont, color: UIColor.Aperio.ink, alignment: .left)
            x += columnWidth + geo.unit * 2
        }

        var rightCursor = top
        let rightWidth = geo.canvas.width * 0.3
        let rightX = bar.maxX - padding - rightWidth

        if let credit = content.credit {
            let font = serifFont(ofSize: geo.unit * 2.2 * configuration.textScaleValue, italic: true)
            draw(credit, at: CGPoint(x: rightX, y: rightCursor), width: rightWidth, font: font, color: UIColor.Aperio.ink.withAlphaComponent(0.85), alignment: .right)
            rightCursor += font.lineHeight + geo.unit * 0.4
        }
        if content.showWatermark {
            let font = UIFont.monospacedSystemFont(ofSize: geo.unit * 1.5, weight: .regular)
            draw("Aperio", at: CGPoint(x: rightX, y: rightCursor), width: rightWidth, font: font, color: UIColor.Aperio.ink.withAlphaComponent(0.5), alignment: .right)
        }
    }

    // MARK: - Créditos

    private static func drawCreditos(
        geo: FrameGeometry,
        content: FrameContent,
        configuration: FrameConfiguration,
        context: UIGraphicsImageRendererContext
    ) {
        let width = geo.canvas.width * 0.88
        let x = geo.canvas.width * 0.06
        var cursor = geo.dataRect.midY - geo.unit * 5

        if let camera = content.cameraLine {
            let font = serifFont(ofSize: geo.unit * 3.2 * configuration.textScaleValue, italic: true)
            draw(camera, at: CGPoint(x: x, y: cursor), width: width, font: font, color: UIColor.Aperio.ink, alignment: .center)
            cursor += font.lineHeight + geo.unit * 0.8
        }

        let settingsFont = UIFont.monospacedSystemFont(ofSize: geo.unit * 1.9 * configuration.textScaleValue, weight: .regular)
        draw(content.settingsLine, at: CGPoint(x: x, y: cursor), width: width, font: settingsFont, color: dataColor(configuration), alignment: .center)
        cursor += settingsFont.lineHeight + geo.unit * 0.8

        if let credit = content.credit {
            let font = serifFont(ofSize: geo.unit * 2.2 * configuration.textScaleValue, italic: true)
            draw(credit, at: CGPoint(x: x, y: cursor), width: width, font: font, color: UIColor.Aperio.ink.withAlphaComponent(0.85), alignment: .center)
            cursor += font.lineHeight + geo.unit * 0.8
        }

        if content.showWatermark {
            let font = UIFont.monospacedSystemFont(ofSize: geo.unit * 1.5, weight: .regular)
            draw("Aperio", at: CGPoint(x: x, y: cursor), width: width, font: font, color: UIColor.Aperio.ink.withAlphaComponent(0.5), alignment: .center)
        }
    }

    // MARK: - Helpers

    /// Serif del sistema (New York), el equivalente de `Theme.Font.display`.
    /// `UIFont.systemFont` da la sans, así que hay que pedir el diseño serif
    /// explícitamente o la exportación no coincide con la vista previa.
    private static func serifFont(ofSize size: CGFloat, italic: Bool = false) -> UIFont {
        let base = UIFont.systemFont(ofSize: size)
        var descriptor = base.fontDescriptor
        if let serif = descriptor.withDesign(.serif) { descriptor = serif }
        if italic, let italicized = descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(.traitItalic)) {
            descriptor = italicized
        }
        return UIFont(descriptor: descriptor, size: size)
    }

    private static func dataColor(_ configuration: FrameConfiguration) -> UIColor {
        switch configuration.accent {
        case .neutro: return UIColor.Aperio.ink.withAlphaComponent(0.75)
        case .ambar: return UIColor.Aperio.accent
        case .blanco: return UIColor.Aperio.ink
        }
    }

    private static func draw(
        _ text: String,
        at origin: CGPoint,
        width: CGFloat,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment
    ) {
        guard !text.isEmpty, width > 0 else { return }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
        ]
        let rect = CGRect(x: origin.x, y: origin.y, width: width, height: font.lineHeight * 1.3)
        (text as NSString).draw(in: rect, withAttributes: attributes)
    }
}

private extension UIImage {
    /// Dibuja la imagen llenando `rect` sin deformarla, recortando el sobrante.
    func drawAspectFilled(in rect: CGRect, context: UIGraphicsImageRendererContext) {
        guard rect.width > 0, rect.height > 0, size.width > 0, size.height > 0 else { return }

        context.cgContext.saveGState()
        context.cgContext.clip(to: rect)

        let imageAspect = size.width / size.height
        let rectAspect = rect.width / rect.height
        let drawRect: CGRect

        if imageAspect > rectAspect {
            let scaledWidth = rect.height * imageAspect
            drawRect = CGRect(x: rect.midX - scaledWidth / 2, y: rect.minY, width: scaledWidth, height: rect.height)
        } else {
            let scaledHeight = rect.width / imageAspect
            drawRect = CGRect(x: rect.minX, y: rect.midY - scaledHeight / 2, width: rect.width, height: scaledHeight)
        }

        draw(in: drawRect)
        context.cgContext.restoreGState()
    }
}
