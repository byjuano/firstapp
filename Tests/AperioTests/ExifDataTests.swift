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

    func testFrameColorClampsToNearestFreeExtreme() {
        XCTAssertEqual(FrameColor(position: 0.2).clampedToFreeTier().position, 0.0)
        XCTAssertEqual(FrameColor(position: 0.8).clampedToFreeTier().position, 1.0)
    }
}
