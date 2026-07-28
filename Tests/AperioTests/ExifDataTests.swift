import CoreGraphics
import XCTest
@testable import Aperio

final class ExifDataTests: XCTestCase {
    func testLabelsFormatKnownValues() {
        var exif = ExifData()
        exif.iso = 400
        exif.aperture = 2.8
        exif.focalLengthMillimeters = 35
        exif.cameraModel = "Fujifilm X100V"
        exif.lensModel = "23mm f/2"

        XCTAssertEqual(exif.isoLabel, "ISO 400")
        XCTAssertEqual(exif.apertureLabel, "f/2.8")
        XCTAssertEqual(exif.focalLengthLabel, "35mm")
        XCTAssertEqual(exif.cameraAndLensLabel, "Fujifilm X100V · 23mm f/2")
    }

    func testLabelsAreNilWhenDataMissing() {
        let exif = ExifData()
        XCTAssertNil(exif.isoLabel)
        XCTAssertNil(exif.apertureLabel)
        XCTAssertNil(exif.focalLengthLabel)
        XCTAssertNil(exif.cameraAndLensLabel)
        XCTAssertTrue(exif.isEmpty)
    }

    func testFreeTierStripsProSettings() {
        var configuration = FrameConfiguration()
        configuration.accent = .ambar
        configuration.textScale = 1.2
        configuration.photographerName = "Juan"
        configuration.visibleFields.dateTimeAndLocation = true
        configuration.visibleFields.photographerCredit = true

        let free = configuration.resolved(isPro: false)
        XCTAssertEqual(free.accent, .neutro)
        XCTAssertEqual(free.textScale, FrameConfiguration.defaultTextScale)
        XCTAssertEqual(free.photographerName, "")
        XCTAssertFalse(free.visibleFields.dateTimeAndLocation)
        XCTAssertFalse(free.visibleFields.photographerCredit)

        // Lo que es gratis no se toca.
        XCTAssertEqual(free.layout, configuration.layout)
        XCTAssertEqual(free.format, configuration.format)
        XCTAssertEqual(free.fit, configuration.fit)
        XCTAssertTrue(free.visibleFields.iso)
    }

    func testProKeepsEverything() {
        var configuration = FrameConfiguration()
        configuration.accent = .ambar
        configuration.textScale = 1.2
        XCTAssertEqual(configuration.resolved(isPro: true), configuration)
    }
}

final class FrameGeometryTests: XCTestCase {
    private let canvas = CGSize(width: 1080, height: 1920) // Stories 9:16

    func testRecortarFillsTheCanvasWithoutBand() {
        var configuration = FrameConfiguration()
        configuration.fit = .recortar

        let geo = FrameGeometry.compute(canvas: canvas, photoAspect: 1.5, configuration: configuration)
        XCTAssertEqual(geo.photoRect, CGRect(origin: .zero, size: canvas))
        XCTAssertFalse(geo.hasBand)
        XCTAssertTrue(geo.needsScrim)
    }

    /// El caso que motivó todo el encuadre: una foto apaisada en Stories.
    func testFotoCompletaKeepsHorizontalPhotoIntact() {
        var configuration = FrameConfiguration()
        configuration.fit = .fotoCompleta

        let geo = FrameGeometry.compute(canvas: canvas, photoAspect: 1.5, configuration: configuration)
        XCTAssertTrue(geo.hasBand)
        XCTAssertFalse(geo.needsScrim)
        // La foto entra entera: conserva su proporción y cabe en el lienzo.
        XCTAssertEqual(geo.photoRect.width / geo.photoRect.height, 1.5, accuracy: 0.01)
        XCTAssertLessThanOrEqual(geo.photoRect.width, canvas.width + 0.01)
        XCTAssertLessThanOrEqual(geo.photoRect.maxY, geo.bandRect.minY + 0.01)
    }

    /// Una foto vertical sobraría de alto, no de ancho. La banda tiene que
    /// existir igual, o los datos se quedarían sin lugar donde ir.
    func testFotoCompletaReservesBandForVerticalPhotoToo() {
        var configuration = FrameConfiguration()
        configuration.fit = .fotoCompleta
        configuration.format = .horizontal

        let horizontalCanvas = CGSize(width: 1080, height: 566)
        let geo = FrameGeometry.compute(canvas: horizontalCanvas, photoAspect: 0.66, configuration: configuration)
        XCTAssertTrue(geo.hasBand)
        XCTAssertEqual(geo.photoRect.width / geo.photoRect.height, 0.66, accuracy: 0.01)
    }

    func testZeroSizedCanvasDoesNotProduceNegativeDimensions() {
        let geo = FrameGeometry.compute(canvas: .zero, photoAspect: 0, configuration: FrameConfiguration())
        XCTAssertGreaterThan(geo.photoRect.width, 0)
        XCTAssertGreaterThan(geo.photoRect.height, 0)
        XCTAssertGreaterThan(geo.unit, 0)
    }
}
