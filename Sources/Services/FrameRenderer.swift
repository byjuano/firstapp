import CoreGraphics
import UIKit

/// Compone la imagen final (foto + marco + datos) para exportar, según el `FrameConfiguration`.
/// El preview en vivo del editor se dibuja aparte en SwiftUI (ver `FramePreviewView`);
/// este renderer es el que produce el archivo que se comparte o se guarda.
enum FrameRenderer {
    static func render(
        photo: UIImage,
        exif: ExifData,
        configuration: FrameConfiguration,
        isPro: Bool
    ) -> UIImage {
        let canvasWidth = configuration.format.exportWidthPixels
        let canvasHeight = canvasWidth / configuration.format.aspectRatio
        let canvasSize = CGSize(width: canvasWidth, height: canvasHeight)

        let colorPosition = isPro ? configuration.color.position : configuration.color.clampedToFreeTier().position
        let sizeFraction = isPro ? configuration.sizeFraction : FrameConfiguration.defaultFreeSize

        let backgroundColor = UIColor.frameTone(atPosition: colorPosition)
        let inkColor = UIColor(white: colorPosition < 0.5 ? 0.11 : 0.94, alpha: 1)

        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: canvasSize))

            switch configuration.layout {
            case .linea:
                drawLinea(photo: photo, exif: exif, configuration: configuration, canvasSize: canvasSize, sizeFraction: sizeFraction, ink: inkColor, background: backgroundColor, context: context)
            case .ficha:
                drawFicha(photo: photo, exif: exif, configuration: configuration, canvasSize: canvasSize, ink: inkColor, background: backgroundColor, context: context)
            case .esquina:
                drawEsquina(photo: photo, exif: exif, configuration: configuration, canvasSize: canvasSize, isDarkFrame: colorPosition >= 0.5, context: context)
            }

            if !isPro {
                drawWatermark(canvasSize: canvasSize, ink: inkColor, context: context)
            }
        }
    }

    // MARK: - Línea: margen fino + una línea de datos debajo

    private static func drawLinea(
        photo: UIImage,
        exif: ExifData,
        configuration: FrameConfiguration,
        canvasSize: CGSize,
        sizeFraction: Double,
        ink: UIColor,
        background: UIColor,
        context: UIGraphicsImageRendererContext
    ) {
        let margin = canvasSize.width * CGFloat(0.02 + sizeFraction * 0.05)
        let captionHeight = canvasSize.height * 0.12
        let photoRect = CGRect(
            x: margin,
            y: margin,
            width: canvasSize.width - margin * 2,
            height: canvasSize.height - margin * 2 - captionHeight
        )
        photo.aspectFilled(in: photoRect, context: context)
        ink.withAlphaComponent(0.9).setStroke()
        UIBezierPath(rect: photoRect).stroke()

        let captionRect = CGRect(
            x: margin,
            y: photoRect.maxY + margin * 0.4,
            width: canvasSize.width - margin * 2,
            height: captionHeight
        )
        draw(
            text: settingsLine(exif: exif, configuration: configuration),
            centeredIn: captionRect,
            font: .monospacedSystemFont(ofSize: canvasSize.width * 0.024, weight: .regular),
            color: ink
        )
    }

    // MARK: - Ficha: franja inferior con grilla de datos

    private static func drawFicha(
        photo: UIImage,
        exif: ExifData,
        configuration: FrameConfiguration,
        canvasSize: CGSize,
        ink: UIColor,
        background: UIColor,
        context: UIGraphicsImageRendererContext
    ) {
        let bandHeight = canvasSize.height * 0.22
        let photoRect = CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height - bandHeight)
        photo.aspectFilled(in: photoRect, context: context)

        let bandRect = CGRect(x: 0, y: photoRect.maxY, width: canvasSize.width, height: bandHeight)
        background.setFill()
        context.fill(bandRect)

        let padding = canvasSize.width * 0.05
        let cameraLine = exif.cameraAndLensLabel ?? "Cámara sin datos EXIF"
        draw(
            text: cameraLine,
            in: CGRect(x: padding, y: bandRect.minY + padding * 0.5, width: canvasSize.width - padding * 2, height: bandHeight * 0.3),
            font: .systemFont(ofSize: canvasSize.width * 0.026, weight: .semibold),
            color: ink,
            alignment: .left
        )

        let stats = statFields(exif: exif, configuration: configuration)
        let columnWidth = (canvasSize.width - padding * 2) / CGFloat(max(stats.count, 1))
        for (index, stat) in stats.enumerated() {
            let columnRect = CGRect(
                x: padding + columnWidth * CGFloat(index),
                y: bandRect.minY + bandHeight * 0.5,
                width: columnWidth,
                height: bandHeight * 0.4
            )
            draw(
                text: "\(stat.label)\n\(stat.value)",
                in: columnRect,
                font: .monospacedSystemFont(ofSize: canvasSize.width * 0.022, weight: .regular),
                color: ink,
                alignment: .left
            )
        }
    }

    // MARK: - Esquina: sin marco, datos en una esquina translúcida

    private static func drawEsquina(
        photo: UIImage,
        exif: ExifData,
        configuration: FrameConfiguration,
        canvasSize: CGSize,
        isDarkFrame: Bool,
        context: UIGraphicsImageRendererContext
    ) {
        let photoRect = CGRect(origin: .zero, size: canvasSize)
        photo.aspectFilled(in: photoRect, context: context)

        let padding = canvasSize.width * 0.035
        let scrimWidth = canvasSize.width * 0.62
        let scrimHeight = canvasSize.height * 0.09
        let scrimRect = CGRect(x: padding, y: canvasSize.height - scrimHeight - padding, width: scrimWidth, height: scrimHeight)

        let scrimColor = isDarkFrame ? UIColor.black.withAlphaComponent(0.55) : UIColor.white.withAlphaComponent(0.72)
        let textColor: UIColor = isDarkFrame ? .white : .black
        let path = UIBezierPath(roundedRect: scrimRect, cornerRadius: 6)
        scrimColor.setFill()
        path.fill()

        draw(
            text: "\(exif.cameraAndLensLabel ?? "")\n\(settingsLine(exif: exif, configuration: configuration))",
            in: scrimRect.insetBy(dx: 10, dy: 6),
            font: .monospacedSystemFont(ofSize: canvasSize.width * 0.02, weight: .regular),
            color: textColor,
            alignment: .left
        )
    }

    private static func drawWatermark(canvasSize: CGSize, ink: UIColor, context: UIGraphicsImageRendererContext) {
        draw(
            text: "Aperio",
            in: CGRect(x: canvasSize.width - 120, y: canvasSize.height - 32, width: 110, height: 20),
            font: .systemFont(ofSize: 12, weight: .medium),
            color: ink.withAlphaComponent(0.55),
            alignment: .right
        )
    }

    // MARK: - Helpers

    private struct Stat { let label: String; let value: String }

    private static func statFields(exif: ExifData, configuration: FrameConfiguration) -> [Stat] {
        var stats: [Stat] = []
        let fields = configuration.visibleFields
        if fields.iso, let value = exif.isoLabel { stats.append(Stat(label: "ISO", value: value)) }
        if fields.aperture, let value = exif.apertureLabel { stats.append(Stat(label: "APERTURA", value: value)) }
        if fields.shutterSpeed, let value = exif.shutterSpeed { stats.append(Stat(label: "VELOCIDAD", value: value)) }
        if fields.focalLength, let value = exif.focalLengthLabel { stats.append(Stat(label: "FOCAL", value: value)) }
        return stats
    }

    private static func settingsLine(exif: ExifData, configuration: FrameConfiguration) -> String {
        let fields = configuration.visibleFields
        var parts: [String] = []
        if fields.focalLength, let value = exif.focalLengthLabel { parts.append(value) }
        if fields.aperture, let value = exif.apertureLabel { parts.append(value) }
        if fields.shutterSpeed, let value = exif.shutterSpeed { parts.append(value) }
        if fields.iso, let value = exif.isoLabel { parts.append(value) }
        return parts.joined(separator: " · ")
    }

    private static func draw(
        text: String,
        centeredIn rect: CGRect,
        font: UIFont,
        color: UIColor
    ) {
        draw(text: text, in: rect, font: font, color: color, alignment: .center)
    }

    private static func draw(
        text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ]
        (text as NSString).draw(in: rect, withAttributes: attributes)
    }
}

private extension UIImage {
    /// Dibuja la imagen recortada para llenar `rect` sin deformarla (equivalente a `aspectRatio(.fill)`).
    func aspectFilled(in rect: CGRect, context: UIGraphicsImageRendererContext) {
        context.cgContext.saveGState()
        context.cgContext.clip(to: rect)

        let imageAspect = size.width / size.height
        let rectAspect = rect.width / rect.height
        var drawRect = rect

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

private extension UIColor {
    /// Tono de marco en el eje claro-oscuro de la marca (papel cálido / tinta cálida),
    /// interpolado linealmente según `position` (0 = claro, 1 = oscuro).
    static func frameTone(atPosition position: Double) -> UIColor {
        let light = (r: Double(0xF7), g: Double(0xF5), b: Double(0xF0))
        let dark = (r: Double(0x17), g: Double(0x14), b: Double(0x0F))
        let t = min(max(position, 0), 1)
        let r = (light.r + (dark.r - light.r) * t) / 255
        let g = (light.g + (dark.g - light.g) * t) / 255
        let b = (light.b + (dark.b - light.b) * t) / 255
        return UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
    }
}
