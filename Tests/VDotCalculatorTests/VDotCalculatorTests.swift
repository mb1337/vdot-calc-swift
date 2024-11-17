import Testing
import Foundation
@testable import VDotCalculator

@Test func projectedRaceTime30() async throws {
    let vdot = Vdot(value: 30)
    #expect(vdot.projectedRaceTime(distance: .init(value: 5000, unit: .meters)).rounded() == 30 * 60 + 41)
    #expect(vdot.projectedRaceTime(distance: .init(value: 10000, unit: .meters)).rounded() == 63 * 60 + 49)
}

@Test func projectedRaceTime55() async throws {
    let vdot = Vdot(value: 55)
    #expect(vdot.projectedRaceTime(distance: .init(value: 5000, unit: .meters)).rounded() == 18 * 60 + 22)
    #expect(vdot.projectedRaceTime(distance: .init(value: 10000, unit: .meters)).rounded() == 38 * 60 + 6)
}

@Test func projectedRaceTime85() async throws {
    let vdot = Vdot(value: 85)
    #expect(vdot.projectedRaceTime(distance: .init(value: 5000, unit: .meters)).rounded() == 12 * 60 + 37)
    #expect(vdot.projectedRaceTime(distance: .init(value: 10000, unit: .meters)).rounded() == 26 * 60 + 19)
}

@Test func targetVelocity55() async throws {
    let vdot = Vdot(value: 55)
    #expect(vdot.trainingVelocity(intensity: .easy).pace(per: .miles).rounded() == 8 * 60 + 45)
    #expect(vdot.trainingVelocity(intensity: .interval).pace(per: .miles).rounded() == 5 * 60 + 51)
    #expect(vdot.trainingVelocity(intensity: .repetition).pace(per: .miles).rounded() == 5 * 60 + 27)
}

extension Measurement where UnitType == UnitSpeed {
    /// Converts speed to pace (time per distance)
    /// - Parameter distanceUnit: Unit of distance for pace calculation
    /// - Returns: Pace in seconds
    public func pace(per distanceUnit: UnitLength) -> TimeInterval {
        let speedInMetersPerSecond = self.converted(to: .metersPerSecond).value
        let distanceInMeters = Measurement<UnitLength>(value: 1, unit: distanceUnit)
            .converted(to: .meters).value
        return distanceInMeters / speedInMetersPerSecond
    }
}
