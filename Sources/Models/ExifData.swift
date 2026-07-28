import CoreLocation
import Foundation

/// Datos técnicos leídos (o corregidos a mano) de una foto.
struct ExifData: Codable, Equatable {
    var cameraModel: String?
    var lensModel: String?
    var iso: Int?
    var aperture: Double?
    var shutterSpeed: String?
    var focalLengthMillimeters: Double?
    var dateTaken: Date?
    var latitude: Double?
    var longitude: Double?

    var isEmpty: Bool {
        cameraModel == nil && lensModel == nil && iso == nil && aperture == nil
            && shutterSpeed == nil && focalLengthMillimeters == nil
    }

    var apertureLabel: String? {
        guard let aperture else { return nil }
        return "f/\(String(format: "%.1f", aperture))"
    }

    var focalLengthLabel: String? {
        guard let focalLengthMillimeters else { return nil }
        return "\(Int(focalLengthMillimeters))mm"
    }

    var isoLabel: String? {
        guard let iso else { return nil }
        return "ISO \(iso)"
    }

    var cameraAndLensLabel: String? {
        switch (cameraModel, lensModel) {
        case let (camera?, lens?): return "\(camera) · \(lens)"
        case let (camera?, nil): return camera
        case let (nil, lens?): return lens
        default: return nil
        }
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
