import SwiftUI

/// Preview en vivo del frame dentro del editor. Redibuja el mismo diseño que
/// `FrameRenderer` compone para exportar, pero con vistas de SwiftUI en vez de
/// Core Graphics, para que reaccione al instante a los cambios de los controles.
struct FramePreviewView: View {
    let photo: UIImage
    let exif: ExifData
    let configuration: FrameConfiguration
    let isPro: Bool

    private var effectiveColorPosition: Double {
        isPro ? configuration.color.position : configuration.color.clampedToFreeTier().position
    }

    private var isDarkFrame: Bool { effectiveColorPosition >= 0.5 }

    private var backgroundTone: Color {
        Color(
            red: (isDarkFrame ? Double(0x17) : Double(0xF7)) / 255,
            green: (isDarkFrame ? Double(0x14) : Double(0xF5)) / 255,
            blue: (isDarkFrame ? Double(0x0F) : Double(0xF0)) / 255
        )
    }

    private var inkTone: Color { isDarkFrame ? .white : Theme.ink }

    var body: some View {
        VStack(spacing: 0) {
            switch configuration.layout {
            case .linea: lineaBody
            case .ficha: fichaBody
            case .esquina: esquinaBody
            }
        }
        .aspectRatio(configuration.format.aspectRatio, contentMode: .fit)
        .background(backgroundTone)
        .overlay(alignment: .bottomTrailing) {
            if !isPro {
                Text("Aperio")
                    .font(Theme.Font.mono(9))
                    .foregroundStyle(inkTone.opacity(0.5))
                    .padding(8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var margin: CGFloat {
        let fraction = isPro ? configuration.sizeFraction : FrameConfiguration.defaultFreeSize
        return 6 + fraction * 14
    }

    // MARK: - Línea

    private var lineaBody: some View {
        VStack(spacing: margin * 0.6) {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .clipped()
                .overlay(RoundedRectangle(cornerRadius: 1).stroke(inkTone.opacity(0.9), lineWidth: 1))
                .padding(margin)

            VStack(spacing: 3) {
                if let camera = exif.cameraModel {
                    Text(camera.uppercased())
                        .font(Theme.Font.mono(8))
                        .tracking(1.2)
                        .foregroundStyle(inkTone.opacity(0.65))
                }
                Text(settingsLine)
                    .font(Theme.Font.mono(11))
                    .foregroundStyle(inkTone)
            }
            .padding(.bottom, margin)
        }
    }

    // MARK: - Ficha

    private var fichaBody: some View {
        VStack(spacing: 0) {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .clipped()
                .layoutPriority(1)

            VStack(alignment: .leading, spacing: 8) {
                if let cameraLine = exif.cameraAndLensLabel {
                    Text(cameraLine)
                        .font(Theme.Font.display(13))
                        .italic()
                        .foregroundStyle(inkTone)
                }
                HStack(spacing: 14) {
                    ForEach(statFields, id: \.label) { stat in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.label)
                                .font(Theme.Font.mono(7))
                                .tracking(0.8)
                                .foregroundStyle(inkTone.opacity(0.6))
                            Text(stat.value)
                                .font(Theme.Font.mono(11))
                                .foregroundStyle(inkTone)
                        }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundTone)
        }
    }

    // MARK: - Esquina

    private var esquinaBody: some View {
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .clipped()

            VStack(alignment: .leading, spacing: 2) {
                if let camera = exif.cameraAndLensLabel {
                    Text(camera)
                        .font(Theme.Font.display(10))
                        .italic()
                }
                Text(settingsLine)
                    .font(Theme.Font.mono(8))
            }
            .foregroundStyle(isDarkFrame ? .white : .black)
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(10)
        }
    }

    // MARK: - Data helpers

    private struct Stat { let label: String; let value: String }

    private var statFields: [Stat] {
        var stats: [Stat] = []
        let fields = configuration.visibleFields
        if fields.iso, let value = exif.isoLabel { stats.append(Stat(label: "ISO", value: value)) }
        if fields.aperture, let value = exif.apertureLabel { stats.append(Stat(label: "APERTURA", value: value)) }
        if fields.shutterSpeed, let value = exif.shutterSpeed { stats.append(Stat(label: "VELOCIDAD", value: value)) }
        if fields.focalLength, let value = exif.focalLengthLabel { stats.append(Stat(label: "FOCAL", value: value)) }
        return stats
    }

    private var settingsLine: String {
        statFields.map(\.value).joined(separator: " · ")
    }
}
