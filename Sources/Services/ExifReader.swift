import CoreGraphics
import Foundation
import ImageIO

/// Lee los metadatos EXIF/GPS de una imagen usando ImageIO.
/// Cuando la foto no trae metadata (capturas de pantalla, escaneos de película),
/// devuelve un `ExifData` vacío para que el usuario complete los campos a mano.
enum ExifReader {
    static func read(from imageData: Data) -> ExifData {
        guard
            let source = CGImageSourceCreateWithData(imageData as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else {
            return ExifData()
        }

        var result = ExifData()

        if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
            result.cameraModel = tiff[kCGImagePropertyTIFFModel] as? String
        }

        if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
            result.lensModel = exif[kCGImagePropertyExifLensModel] as? String
            result.iso = (exif[kCGImagePropertyExifISOSpeedRatings] as? [Int])?.first
            result.aperture = exif[kCGImagePropertyExifFNumber] as? Double
            result.focalLengthMillimeters = exif[kCGImagePropertyExifFocalLength] as? Double

            if let exposureTime = exif[kCGImagePropertyExifExposureTime] as? Double, exposureTime > 0 {
                result.shutterSpeed = exposureTime >= 1
                    ? "\(Int(exposureTime))s"
                    : "1/\(Int(round(1 / exposureTime)))s"
            }

            if let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
                result.dateTaken = Self.exifDateFormatter.date(from: dateString)
            }
        }

        if let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
            if let lat = gps[kCGImagePropertyGPSLatitude] as? Double {
                let ref = gps[kCGImagePropertyGPSLatitudeRef] as? String
                result.latitude = (ref == "S") ? -lat : lat
            }
            if let lon = gps[kCGImagePropertyGPSLongitude] as? Double {
                let ref = gps[kCGImagePropertyGPSLongitudeRef] as? String
                result.longitude = (ref == "W") ? -lon : lon
            }
        }

        return result
    }

    private static let exifDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
