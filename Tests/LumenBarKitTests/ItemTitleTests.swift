import Foundation
import XCTest
@testable import LumenBarKit

final class LumenBarKitTests: XCTestCase {
    func testModesAndPresetsCount() {
        XCTAssertEqual(AutomationMode.allCases.count, 3)
        XCTAssertEqual(FilterPresetType.allCases.count, 11)
        XCTAssertEqual(OverlayPigment.allCases.count, 12)
    }

    func testKelvinLUTExactMatch() {
        XCTAssertEqual(KelvinLUT.table.count, 101)

        let k0 = KelvinLUT.rgb(forKelvin: 0)
        XCTAssertEqual(k0.red, 1.0)
        XCTAssertEqual(k0.green, 0.0)
        XCTAssertEqual(k0.blue, 0.0)

        let k3400 = KelvinLUT.rgb(forKelvin: 3400)
        XCTAssertEqual(k3400.red, 1.0, accuracy: 0.0001)
        XCTAssertEqual(k3400.green, 0.76888305, accuracy: 0.0001)
        XCTAssertEqual(k3400.blue, 0.52427316, accuracy: 0.0001)

        let k6500 = KelvinLUT.rgb(forKelvin: 6500)
        XCTAssertEqual(k6500.red, 1.0)
        XCTAssertEqual(k6500.green, 1.0)
        XCTAssertEqual(k6500.blue, 1.0)

        let k3450 = KelvinLUT.rgb(forKelvin: 3450)
        XCTAssertTrue(k3450.green > k3400.green && k3450.green < KelvinLUT.rgb(forKelvin: 3500).green)
    }

    func testPresetSpecificationsMatchProfiles() {
        let healthPro = FilterPresetType.health.specification(for: .pro)
        XCTAssertEqual(healthPro.day, PhaseTarget(kelvin: 5000, brightnessPercent: 100))
        XCTAssertEqual(healthPro.night, PhaseTarget(kelvin: 3400, brightnessPercent: 80))
        XCTAssertEqual(healthPro.sleep, PhaseTarget(kelvin: 2700, brightnessPercent: 75))

        let healthStd = FilterPresetType.health.specification(for: .standard)
        XCTAssertEqual(healthStd.day, PhaseTarget(kelvin: 6000, brightnessPercent: 100))
        XCTAssertEqual(healthStd.night, PhaseTarget(kelvin: 4400, brightnessPercent: 85))
        XCTAssertEqual(healthStd.sleep, PhaseTarget(kelvin: 3700, brightnessPercent: 80))

        let sleepPro = FilterPresetType.sleep.specification(for: .pro)
        XCTAssertEqual(sleepPro.night, PhaseTarget(kelvin: 0, brightnessPercent: 80))

        let biohacker = FilterPresetType.biohacker.specification(for: .pro)
        XCTAssertEqual(biohacker.night.kelvin, 0)
        XCTAssertTrue(biohacker.invertsColors)

        let reading = FilterPresetType.reading.specification(for: .pro)
        XCTAssertTrue(reading.usesGrayscale)

        let programming = FilterPresetType.programming.specification(for: .pro)
        XCTAssertTrue(programming.invertsColors)

        let sunglasses = FilterPresetType.sunglasses.specification(for: .pro)
        XCTAssertEqual(sunglasses.night, PhaseTarget(kelvin: 6500, brightnessPercent: 75))
        XCTAssertEqual(sunglasses.sleep, PhaseTarget(kelvin: 6500, brightnessPercent: 65))

        let dark = FilterPresetType.dark.specification(for: .pro)
        XCTAssertTrue(dark.usesDarkVignette)

        let movie = FilterPresetType.movie.specification(for: .pro)
        XCTAssertEqual(movie.night, PhaseTarget(kelvin: 6500, brightnessPercent: 120))

        let overlay = FilterPresetType.overlay.specification(for: .pro)
        XCTAssertTrue(overlay.usesOverlayTint)
        XCTAssertEqual(overlay.dayOverlayOpacity, 5)
        XCTAssertEqual(overlay.nightOverlayOpacity, 40)
        XCTAssertEqual(overlay.nightOverlayDim, 10)
    }

    func testGammaRampBuilder() {
        let normal = GammaRampBuilder.buildTables(kelvin: 6500, brightnessPercent: 100, inverted: false)
        XCTAssertEqual(normal.capacity, 256)
        XCTAssertEqual(normal.red.first ?? -1, 0.0, accuracy: 0.0001)
        XCTAssertEqual(normal.red.last ?? -1, 1.0, accuracy: 0.0001)

        let sleepRed = GammaRampBuilder.buildTables(kelvin: 0, brightnessPercent: 80, inverted: false)
        XCTAssertEqual(sleepRed.red.last ?? -1, 0.8, accuracy: 0.001)
        XCTAssertEqual(sleepRed.green.last ?? -1, 0.0, accuracy: 0.0001)
        XCTAssertEqual(sleepRed.blue.last ?? -1, 0.0, accuracy: 0.0001)

        let biohackerInverted = GammaRampBuilder.buildTables(kelvin: 0, brightnessPercent: 80, inverted: true)
        XCTAssertEqual(biohackerInverted.red.first ?? -1, 0.8, accuracy: 0.001)
        XCTAssertEqual(biohackerInverted.red.last ?? -1, 0.0, accuracy: 0.0001)
        XCTAssertEqual(biohackerInverted.blue.first ?? -1, 0.0, accuracy: 0.0001)

        let movieBoost = GammaRampBuilder.buildTables(kelvin: 6500, brightnessPercent: 120, inverted: false)
        XCTAssertGreaterThan(movieBoost.red[128], normal.red[128])
    }

    func testOverlayPigmentScaling() {
        let turquoise = OverlayPigment.turquoise.dimmedRGB255(screenDimPercent: 0)
        XCTAssertEqual(turquoise.r, 0x40)
        XCTAssertEqual(turquoise.g, 0xE0)
        XCTAssertEqual(turquoise.b, 0xD0)

        let orangeDimmed10 = OverlayPigment.orange.dimmedRGB255(screenDimPercent: 10)
        XCTAssertEqual(orangeDimmed10.r, (255 * 90) / 100)
        XCTAssertEqual(orangeDimmed10.g, (165 * 90) / 100)
        XCTAssertEqual(orangeDimmed10.b, 0)
    }

    func testPresetMarkImageNames() {
        for preset in FilterPresetType.allCases {
            XCTAssertEqual(preset.markImageName, "preset-mark-\(preset.rawValue)")
        }
    }

    func testSolarScheduleEstimator() {
        let hours = SolarScheduleEstimator.estimatedHours()
        XCTAssertGreaterThanOrEqual(hours.dayStartHour, 0)
        XCTAssertLessThan(hours.dayStartHour, 24)
        XCTAssertGreaterThan(hours.nightStartHour, hours.dayStartHour)
    }

    func testCircadianSchedulerInterpolation() {
        let spec = FilterPresetType.health.specification(for: .pro)
        let schedule = CircadianScheduleConfig(
            dayStartHour: 7.0,
            nightStartHour: 19.0,
            sleepStartHour: 23.0,
            transitionDurationMinutes: 60.0,
            useSleepPhase: true
        )

        let midday = CircadianScheduler.evaluate(hourOfDay: 13.0, spec: spec, schedule: schedule)
        XCTAssertEqual(midday.phase, .day)
        XCTAssertEqual(midday.kelvin, 5000)
        XCTAssertEqual(midday.brightnessPercent, 100)

        let halfSunset = CircadianScheduler.evaluate(hourOfDay: 19.5, spec: spec, schedule: schedule)
        XCTAssertEqual(halfSunset.phase, .night)
        XCTAssertEqual(halfSunset.kelvin, 4200)
        XCTAssertEqual(halfSunset.brightnessPercent, 90)

        let deepNight = CircadianScheduler.evaluate(hourOfDay: 21.0, spec: spec, schedule: schedule)
        XCTAssertEqual(deepNight.phase, .night)
        XCTAssertEqual(deepNight.kelvin, 3400)
        XCTAssertEqual(deepNight.brightnessPercent, 80)

        let lateSleep = CircadianScheduler.evaluate(hourOfDay: 1.5, spec: spec, schedule: schedule)
        XCTAssertEqual(lateSleep.phase, .sleep)
        XCTAssertEqual(lateSleep.kelvin, 2700)
        XCTAssertEqual(lateSleep.brightnessPercent, 75)
    }
}
