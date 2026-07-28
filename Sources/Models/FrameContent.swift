import Foundation

/// Los textos que se dibujan sobre la foto, ya resueltos a partir del EXIF y de
/// la configuración.
///
/// Antes esta lógica estaba duplicada en la vista previa y en el render final,
/// que es exactamente el tipo de duplicación que hace que lo que se ve y lo que
/// se exporta se separen con el tiempo.
struct FrameContent {
    struct Stat: Identifiable {
        let label: String
        let value: String
        var id: String { label }
    }

    let stats: [Stat]
    let cameraLine: String?
    let settingsLine: String
    let credit: String?
    let showWatermark: Bool

    init(exif: ExifData, configuration: FrameConfiguration, isPro: Bool) {
        let resolved = configuration.resolved(isPro: isPro)
        let fields = resolved.visibleFields

        var stats: [Stat] = []
        if fields.iso, let value = exif.isoLabel { stats.append(Stat(label: "ISO", value: value)) }
        if fields.aperture, let value = exif.apertureLabel { stats.append(Stat(label: "APERTURA", value: value)) }
        if fields.shutterSpeed, let value = exif.shutterSpeed { stats.append(Stat(label: "VELOCIDAD", value: value)) }
        if fields.focalLength, let value = exif.focalLengthLabel { stats.append(Stat(label: "FOCAL", value: value)) }
        self.stats = stats

        self.cameraLine = fields.cameraAndLens ? exif.cameraAndLensLabel : nil
        self.settingsLine = stats.map(\.value).joined(separator: " · ")

        if fields.photographerCredit, !resolved.photographerName.isEmpty {
            self.credit = resolved.photographerName
        } else {
            self.credit = nil
        }

        self.showWatermark = !isPro
    }

    var isEmpty: Bool { stats.isEmpty && cameraLine == nil && credit == nil }
}
