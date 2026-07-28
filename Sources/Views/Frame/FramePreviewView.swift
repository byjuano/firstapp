import SwiftUI

/// Vista previa en vivo de la composición.
///
/// Recibe un `size` ya resuelto en vez de calcularlo con `aspectRatio`: dentro
/// de un `ScrollView`, `aspectRatio` puede dimensionarse contra el tamaño ideal
/// del contenido y no contra el ancho disponible, lo que recorta la vista y
/// hace que cambiar de formato no se refleje.
struct FramePreviewView: View {
    let photo: UIImage
    let exif: ExifData
    let configuration: FrameConfiguration
    let isPro: Bool
    let size: CGSize

    private var resolved: FrameConfiguration { configuration.resolved(isPro: isPro) }

    private var geometry: FrameGeometry {
        FrameGeometry.compute(
            canvas: size,
            photoAspect: photo.size.height > 0 ? photo.size.width / photo.size.height : 1,
            configuration: resolved
        )
    }

    private var content: FrameContent {
        FrameContent(exif: exif, configuration: configuration, isPro: isPro)
    }

    /// Color de la línea de datos según el tinte elegido en Pro.
    private var dataTextColor: Color {
        switch resolved.accent {
        case .neutro: return Theme.ink.opacity(0.75)
        case .ambar: return Theme.accent
        case .blanco: return Theme.ink
        }
    }

    var body: some View {
        let geo = geometry

        ZStack(alignment: .topLeading) {
            Theme.void

            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: geo.photoRect.width, height: geo.photoRect.height)
                .clipped()
                .offset(x: geo.photoRect.minX, y: geo.photoRect.minY)

            if geo.needsScrim {
                LinearGradient(
                    colors: [.black.opacity(0.82), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: geo.canvas.height * 0.36)
                .offset(y: geo.canvas.height * 0.64)
                .allowsHitTesting(false)
            }

            switch resolved.layout {
            case .visor: visorOverlay(geo)
            case .claqueta: claquetaOverlay(geo)
            case .creditos: creditosOverlay(geo)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    // MARK: - Visor

    /// Los brackets abrazan la foto, no el lienzo: son parte del encuadre de la
    /// toma, así que cuando hay bandas siguen a la imagen.
    private func visorOverlay(_ geo: FrameGeometry) -> some View {
        let inset = geo.photoRect.width * 0.06

        return ZStack(alignment: .topLeading) {
            CornerBrackets(length: geo.unit * 3.5)
                .stroke(Theme.ink.opacity(0.9), lineWidth: max(geo.unit * 0.18, 0.5))
                .frame(
                    width: max(geo.photoRect.width - inset * 2, 1),
                    height: max(geo.photoRect.height - inset * 2, 1)
                )
                .offset(x: geo.photoRect.minX + inset, y: geo.photoRect.minY + inset)

            VStack(alignment: .leading, spacing: geo.unit * 0.6) {
                if let camera = content.cameraLine {
                    Text(camera.uppercased())
                        .font(Theme.Font.mono(geo.unit * 2.4 * resolved.textScaleValue))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Text(content.settingsLine)
                    .font(Theme.Font.mono(geo.unit * 2.1 * resolved.textScaleValue))
                    .foregroundStyle(dataTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                creditLine(geo)
            }
            .frame(width: geo.canvas.width * 0.72, alignment: .leading)
            .offset(x: geo.unit * 8, y: geo.dataRect.midY - geo.unit * 4)

            if content.showWatermark {
                watermark(geo)
                    .frame(width: geo.canvas.width, alignment: .trailing)
                    .offset(x: -geo.unit * 8, y: geo.dataRect.midY - geo.unit * 1)
            }
        }
    }

    // MARK: - Claqueta

    /// Con bandas, la franja y la banda son el mismo rectángulo: no hay
    /// superposición sobre la foto ni espacio desaprovechado.
    private func claquetaOverlay(_ geo: FrameGeometry) -> some View {
        let bar = geo.hasBand
            ? geo.bandRect
            : CGRect(
                x: 0,
                y: geo.canvas.height - geo.canvas.height * 0.20,
                width: geo.canvas.width,
                height: geo.canvas.height * 0.20
            )

        return VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.accent)
                .frame(height: max(geo.unit * 0.4, 1))

            HStack(alignment: .center, spacing: geo.unit * 4) {
                ForEach(content.stats) { stat in
                    VStack(alignment: .leading, spacing: geo.unit * 0.4) {
                        Text(stat.label)
                            .font(Theme.Font.mono(geo.unit * 1.5 * resolved.textScaleValue))
                            .foregroundStyle(Theme.accent)
                            .lineLimit(1)
                        Text(stat.value)
                            .font(Theme.Font.mono(geo.unit * 2.3 * resolved.textScaleValue, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: geo.unit * 0.4) {
                    creditLine(geo)
                    if content.showWatermark { watermark(geo) }
                }
            }
            .padding(.horizontal, geo.unit * 7)
            .frame(maxHeight: .infinity)
        }
        .frame(width: bar.width, height: bar.height)
        .background(geo.hasBand ? Theme.void : Color.black.opacity(0.82))
        .offset(y: bar.minY)
    }

    // MARK: - Créditos

    private func creditosOverlay(_ geo: FrameGeometry) -> some View {
        VStack(spacing: geo.unit * 0.8) {
            if let camera = content.cameraLine {
                Text(camera)
                    .font(Theme.Font.display(geo.unit * 3.2 * resolved.textScaleValue))
                    .italic()
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Text(content.settingsLine)
                .font(Theme.Font.mono(geo.unit * 1.9 * resolved.textScaleValue))
                .foregroundStyle(dataTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            creditLine(geo)
            if content.showWatermark { watermark(geo) }
        }
        .multilineTextAlignment(.center)
        .frame(width: geo.canvas.width * 0.88)
        .offset(x: geo.canvas.width * 0.06, y: geo.dataRect.midY - geo.unit * 5)
    }

    // MARK: - Piezas compartidas

    @ViewBuilder
    private func creditLine(_ geo: FrameGeometry) -> some View {
        if let credit = content.credit {
            Text(credit)
                .font(Theme.Font.display(geo.unit * 2.2 * resolved.textScaleValue))
                .italic()
                .foregroundStyle(Theme.ink.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private func watermark(_ geo: FrameGeometry) -> some View {
        Text("Aperio")
            .font(Theme.Font.mono(geo.unit * 1.5))
            .tracking(geo.unit * 0.12)
            .foregroundStyle(Theme.ink.opacity(0.5))
    }
}

/// Cuatro brackets de esquina, sin los lados. Es la forma del punto de enfoque
/// de un visor: sugiere el encuadre sin encerrar la foto en un marco.
private struct CornerBrackets: Shape {
    let length: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let l = min(length, min(rect.width, rect.height) / 2)

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + l))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + l, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - l, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + l))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - l))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - l, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX + l, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - l))

        return path
    }
}
