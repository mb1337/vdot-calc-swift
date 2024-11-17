//
//  Vdot.swift
//  VDotCalculator
//
//  Based on "Oxygen Power: Performance Tables for Distance Runners" by Jack Daniels and Jimmy Gilbert
//

import Foundation

public struct Vdot {
    /// VDOT value representing runner's current fitness level
    public let value: Double
    
    /// Creates a new VDOT calculator
    /// - Parameter value: VDOT value (typically between 30-80)
    public init(value: Double) {
        self.value = value
    }
    
    /// Creates a new VDOT calculator based on a recent race result
    /// - Parameters:
    ///   - raceDistance: Recent race distance
    ///   - raceTime: Recent race time in seconds
    public init(raceDistance: Measurement<UnitLength>, raceTime: TimeInterval) {
        self.value = Self.vdot(distance: raceDistance.converted(to: .meters).value, time: raceTime / 60)
    }
    
    /// Common training intensities as defined in Daniels' Running Formula
    public enum TrainingIntensity: Double {
        case easy = 0.59         // Easy/Recovery runs
        case marathon = 0.75     // Marathon pace
        case threshold = 0.83    // Threshold/Tempo runs
        case interval = 0.97     // Interval training
        case repetition = 1.06   // Repetition/Speed work
    }
    
    /// Training velocity based on current VDOT
    /// - Parameter intensity: Intensity as percent of VO2 max
    /// - Returns: Velocity measurement
    public func trainingVelocity(intensity: Double) -> Measurement<UnitSpeed> {
        return Measurement<UnitSpeed>(
            value: Self.velocity(vdot: self.value, intensity: intensity) / 60,
            unit: .metersPerSecond
        )
    }
    
    /// Training velocity based on current VDOT
    /// - Parameter intensity: Intensity category
    /// - Returns: Velocity measurement
    public func trainingVelocity(intensity: TrainingIntensity) -> Measurement<UnitSpeed> {
        trainingVelocity(intensity: intensity.rawValue)
    }
    
    /// Projected race time based on current VDOT value
    /// - Parameter distance: Race distance
    /// - Returns: Time in seconds
    public func projectedRaceTime(distance: Measurement<UnitLength>) -> TimeInterval {
        let meters = distance.converted(to: .meters).value
        return Self.time(vdot: self.value, distance: meters) * 60
    }
    
    // MARK: - Private Methods
    // All distances are in meters and all times are in minutes
    
    /// Constants used in VDOT calculations
    private enum Constants {
        static let vo2Cost = (a: 0.000104, b: 0.182258, c: -4.60)
        static let intensity = (p0: 0.8, p1: 0.2989558, p2: 0.1894393, k1: -0.1932605, k2: -0.012778)
        static let velocity = (a: -0.007546, b: 5.000663, c: 29.54)
    }
    
    private static func vo2Cost(distance: Double, time: Double) -> Double {
        vo2Cost(velocity: distance / time)
    }
    
    private static func vo2Cost_dt(distance: Double, time: Double) -> Double {
        let (a, b, _) = Constants.vo2Cost
        return ((-2 * a * distance * distance) / pow(time, 3)) -
        ((b * distance) / (time * time))
    }
    
    private static func vo2Cost(velocity: Double) -> Double {
        let (a, b, c) = Constants.vo2Cost
        return (a * velocity * velocity) + (b * velocity) + c
    }
    
    private static func intensity(time: Double) -> Double {
        let (p0, p1, p2, k1, k2) = Constants.intensity
        return (p1 * exp(k1 * time)) + (p2 * exp(k2 * time)) + p0
    }
    
    private static func intensity_dt(time: Double) -> Double {
        let (_, p1, p2, k1, k2) = Constants.intensity
        return (k1 * p1 * exp(k1 * time)) + (k2 * p2 * exp(k2 * time))
    }
    
    private static func velocity(vdot: Double, intensity: Double) -> Double {
        let vo2 = vdot * intensity
        let (a, b, c) = Constants.velocity
        return (a * vo2 * vo2) + (b * vo2) + c
    }
    
    private static func time(vdot: Double, distance: Double) -> TimeInterval {
        var t = distance / 280 // Initial guess based on rough 280m/min pace
        
        // Use Newton's method to converge on value of time
        for _ in 0..<1000 {
            let intensity = intensity(time: t)
            let vo2Cost = vo2Cost(distance: distance, time: t)
            let check = (vo2Cost / vdot) - intensity
            
            if abs(check) < Double.ulpOfOne {
                return t
            }
            
            let derivative = (vo2Cost_dt(distance: distance, time: t) / vdot) -
            (intensity_dt(time: t))
            let diff = check / derivative
            t = t - diff
            
            if diff.magnitude < 0.001 {
                return t
            }
        }
        fatalError("Failed to converge on value")
    }
    
    private static func vdot(distance: Double, time: Double) -> Double {
        return vo2Cost(distance: distance, time: time) / intensity(time: time)
    }
}
