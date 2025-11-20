import Foundation

struct LapTelemetrySample: Identifiable, Codable {
    let id: UUID
    let distance: Double
    let speed: Double
    let throttle: Double
    let brake: Double
    let gear: Double
    
    init(
        id: UUID = UUID(),
        distance: Double,
        speed: Double,
        throttle: Double,
        brake: Double,
        gear: Double
    ) {
        self.id = id
        self.distance = distance
        self.speed = speed
        self.throttle = throttle
        self.brake = brake
        self.gear = gear
    }
    
    static func placeholderSeries(
        lapTimeMS: Int32,
        resolution: Int = 64
    ) -> [LapTelemetrySample] {
        guard resolution > 1 else { return [] }
        return (0..<resolution).map { index in
            let progress = Double(index) / Double(resolution - 1)
            let accel = sin(progress * .pi)
            let corner = sin(progress * .pi * 1.4 + .pi / 4)
            let speed = max(80, 90 + accel * 190 - abs(corner) * 20)
            let throttle = min(100, max(0, accel * 95 + cos(progress * .pi * 2) * 8))
            let brake = min(100, max(0, (1 - accel * 0.7) * abs(corner) * 90))
            let gear = max(1, min(8, round(progress * 8)))
            
            return LapTelemetrySample(
                distance: progress,
                speed: speed,
                throttle: throttle,
                brake: brake,
                gear: gear
            )
        }
    }
}

