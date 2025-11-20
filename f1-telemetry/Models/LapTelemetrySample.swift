import Foundation

struct LapTelemetrySample: Identifiable, Codable {
    let id: UUID
    let distance: Double
    let speed: Double
    let throttle: Double
    let brake: Double
    let gear: Double
    let rpm: Double
    let steer: Double
    let lateralG: Double
    let longitudinalG: Double
    let frontSlip: Double
    let rearSlip: Double
    
    init(
        id: UUID = UUID(),
        distance: Double,
        speed: Double,
        throttle: Double,
        brake: Double,
        gear: Double,
        rpm: Double = 0,
        steer: Double = 0,
        lateralG: Double = 0,
        longitudinalG: Double = 0,
        frontSlip: Double = 0,
        rearSlip: Double = 0
    ) {
        self.id = id
        self.distance = distance
        self.speed = speed
        self.throttle = throttle
        self.brake = brake
        self.gear = gear
        self.rpm = rpm
        self.steer = steer
        self.lateralG = lateralG
        self.longitudinalG = longitudinalG
        self.frontSlip = frontSlip
        self.rearSlip = rearSlip
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
            let rpm = speed * 45
            let steer = sin(progress * .pi * 1.6) * 0.6
            let latG = corner * 3.2
            let longG = accel * 2.5
            
            return LapTelemetrySample(
                distance: progress,
                speed: speed,
                throttle: throttle,
                brake: brake,
                gear: gear,
                rpm: rpm,
                steer: steer,
                lateralG: latG,
                longitudinalG: longG,
                frontSlip: abs(corner) * 0.1,
                rearSlip: abs(accel - 0.5) * 0.08
            )
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case distance
        case speed
        case throttle
        case brake
        case gear
        case rpm
        case steer
        case lateralG
        case longitudinalG
        case frontSlip
        case rearSlip
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        distance = try container.decode(Double.self, forKey: .distance)
        speed = try container.decode(Double.self, forKey: .speed)
        throttle = try container.decode(Double.self, forKey: .throttle)
        brake = try container.decode(Double.self, forKey: .brake)
        gear = try container.decode(Double.self, forKey: .gear)
        rpm = try container.decodeIfPresent(Double.self, forKey: .rpm) ?? 0
        steer = try container.decodeIfPresent(Double.self, forKey: .steer) ?? 0
        lateralG = try container.decodeIfPresent(Double.self, forKey: .lateralG) ?? 0
        longitudinalG = try container.decodeIfPresent(Double.self, forKey: .longitudinalG) ?? 0
        frontSlip = try container.decodeIfPresent(Double.self, forKey: .frontSlip) ?? 0
        rearSlip = try container.decodeIfPresent(Double.self, forKey: .rearSlip) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(distance, forKey: .distance)
        try container.encode(speed, forKey: .speed)
        try container.encode(throttle, forKey: .throttle)
        try container.encode(brake, forKey: .brake)
        try container.encode(gear, forKey: .gear)
        try container.encode(rpm, forKey: .rpm)
        try container.encode(steer, forKey: .steer)
        try container.encode(lateralG, forKey: .lateralG)
        try container.encode(longitudinalG, forKey: .longitudinalG)
        try container.encode(frontSlip, forKey: .frontSlip)
        try container.encode(rearSlip, forKey: .rearSlip)
    }
}

