//
//  TelemetryPackets.swift
//  f1-tracker
//
//  F1 24 UDP Telemetry Packet Structures
//

import Foundation

// MARK: - Packet Header (common to all packets)
struct PacketHeader {
    var packetFormat: UInt16         // 2024
    var gameYear: UInt8              // Game year - last two digits e.g. 24
    var gameMajorVersion: UInt8      // Game major version - "X.00"
    var gameMinorVersion: UInt8      // Game minor version - "1.XX"
    var packetVersion: UInt8         // Version of this packet type
    var packetId: UInt8              // Identifier for the packet type
    var sessionUID: UInt64           // Unique identifier for the session
    var sessionTime: Float           // Session timestamp
    var frameIdentifier: UInt32      // Identifier for the frame the data was retrieved on
    var overallFrameIdentifier: UInt32 // Overall identifier for the frame
    var playerCarIndex: UInt8        // Index of player's car in the array
    var secondaryPlayerCarIndex: UInt8 // Index of secondary player's car
    
    static let size = 29
    
    init(data: Data) {
        var offset = 0
        
        func read<T>(_ type: T.Type) -> T {
            let size = MemoryLayout<T>.size
            let value = data.subdata(in: offset..<offset+size).withUnsafeBytes { $0.load(as: T.self) }
            offset += size
            return value
        }
        
        packetFormat = read(UInt16.self)
        gameYear = read(UInt8.self)
        gameMajorVersion = read(UInt8.self)
        gameMinorVersion = read(UInt8.self)
        packetVersion = read(UInt8.self)
        packetId = read(UInt8.self)
        sessionUID = read(UInt64.self)
        sessionTime = read(Float.self)
        frameIdentifier = read(UInt32.self)
        overallFrameIdentifier = read(UInt32.self)
        playerCarIndex = read(UInt8.self)
        secondaryPlayerCarIndex = read(UInt8.self)
    }
}

// MARK: - Packet IDs
enum PacketType: UInt8 {
    case motion = 0
    case session = 1
    case lapData = 2
    case event = 3
    case participants = 4
    case carSetups = 5
    case carTelemetry = 6
    case carStatus = 7
    case finalClassification = 8
    case lobbyInfo = 9
    case carDamage = 10
    case sessionHistory = 11
    case tyreSets = 12
    case motionEx = 13
}

// MARK: - Car Telemetry Data (Packet ID 6)
struct CarTelemetryData {
    var speed: UInt16                    // Speed of car in kilometres per hour
    var throttle: Float                  // Amount of throttle applied (0.0 to 1.0)
    var steer: Float                     // Steering (-1.0 (full lock left) to 1.0 (full lock right))
    var brake: Float                     // Amount of brake applied (0.0 to 1.0)
    var clutch: UInt8                    // Amount of clutch applied (0 to 100)
    var gear: Int8                       // Gear selected (1-8, N=0, R=-1)
    var engineRPM: UInt16                // Engine RPM
    var drs: UInt8                       // 0 = off, 1 = on
    var revLightsPercent: UInt8          // Rev lights indicator (percentage)
    var revLightsBitValue: UInt16        // Rev lights (bit 0 = leftmost LED, bit 14 = rightmost LED)
    var brakesTemperature: [UInt16]      // Brakes temperature (celsius) [RL, RR, FL, FR]
    var tyresSurfaceTemperature: [UInt8] // Tyres surface temperature (celsius) [RL, RR, FL, FR]
    var tyresInnerTemperature: [UInt8]   // Tyres inner temperature (celsius) [RL, RR, FL, FR]
    var engineTemperature: UInt16        // Engine temperature (celsius)
    var tyresPressure: [Float]           // Tyres pressure (PSI) [RL, RR, FL, FR]
    var surfaceType: [UInt8]             // Driving surface [RL, RR, FL, FR]
    
    static let size = 60
    
    init(data: Data, offset: inout Int) {
        func read<T>(_ type: T.Type) -> T {
            let size = MemoryLayout<T>.size
            let value = data.subdata(in: offset..<offset+size).withUnsafeBytes { $0.load(as: T.self) }
            offset += size
            return value
        }
        
        func readArray<T>(_ type: T.Type, count: Int) -> [T] {
            var array: [T] = []
            for _ in 0..<count {
                array.append(read(type))
            }
            return array
        }
        
        speed = read(UInt16.self)
        throttle = read(Float.self)
        steer = read(Float.self)
        brake = read(Float.self)
        clutch = read(UInt8.self)
        gear = read(Int8.self)
        engineRPM = read(UInt16.self)
        drs = read(UInt8.self)
        revLightsPercent = read(UInt8.self)
        revLightsBitValue = read(UInt16.self)
        brakesTemperature = readArray(UInt16.self, count: 4)
        tyresSurfaceTemperature = readArray(UInt8.self, count: 4)
        tyresInnerTemperature = readArray(UInt8.self, count: 4)
        engineTemperature = read(UInt16.self)
        tyresPressure = readArray(Float.self, count: 4)
        surfaceType = readArray(UInt8.self, count: 4)
    }
}

struct PacketCarTelemetryData {
    var header: PacketHeader
    var carTelemetryData: [CarTelemetryData] // Data for all cars (22 cars max)
    var mfdPanelIndex: UInt8
    var mfdPanelIndexSecondaryPlayer: UInt8
    var suggestedGear: Int8
    
    init?(data: Data) {
        guard data.count >= PacketHeader.size else { return nil }
        
        header = PacketHeader(data: data)
        
        var offset = PacketHeader.size
        var telemetryArray: [CarTelemetryData] = []
        
        // Parse telemetry for all 22 cars
        for _ in 0..<22 {
            guard offset + CarTelemetryData.size <= data.count else { return nil }
            let telemetry = CarTelemetryData(data: data, offset: &offset)
            telemetryArray.append(telemetry)
        }
        
        carTelemetryData = telemetryArray
        
        guard offset + 3 <= data.count else { return nil }
        mfdPanelIndex = data[offset]
        offset += 1
        mfdPanelIndexSecondaryPlayer = data[offset]
        offset += 1
        suggestedGear = Int8(bitPattern: data[offset])
    }
}

// MARK: - Lap Data (Packet ID 2)
struct LapData {
    var lastLapTimeInMS: UInt32              // Last lap time in milliseconds
    var currentLapTimeInMS: UInt32           // Current time around the lap in milliseconds
    var sector1TimeInMS: UInt16              // Sector 1 time in milliseconds
    var sector1TimeMinutes: UInt8            // Sector 1 whole minute part
    var sector2TimeInMS: UInt16              // Sector 2 time in milliseconds
    var sector2TimeMinutes: UInt8            // Sector 2 whole minute part
    var deltaToCarInFrontInMS: UInt16        // Time delta to car in front in milliseconds
    var deltaToRaceLeaderInMS: UInt16        // Time delta to race leader in milliseconds
    var lapDistance: Float                   // Distance vehicle is around current lap in metres
    var totalDistance: Float                 // Total distance travelled in session in metres
    var safetyCarDelta: Float                // Delta in seconds for safety car
    var carPosition: UInt8                   // Car race position
    var currentLapNum: UInt8                 // Current lap number
    var pitStatus: UInt8                     // 0 = none, 1 = pitting, 2 = in pit area
    var numPitStops: UInt8                   // Number of pit stops taken in this race
    var sector: UInt8                        // 0 = sector1, 1 = sector2, 2 = sector3
    var currentLapInvalid: UInt8             // Current lap invalid - 0 = valid, 1 = invalid
    var penalties: UInt8                     // Accumulated time penalties in seconds to be added
    var totalWarnings: UInt8                 // Accumulated number of warnings issued
    var cornerCuttingWarnings: UInt8         // Accumulated number of corner cutting warnings
    var numUnservedDriveThroughPens: UInt8   // Num drive through pens left to serve
    var numUnservedStopGoPens: UInt8         // Num stop go pens left to serve
    var gridPosition: UInt8                  // Grid position the vehicle started the race in
    var driverStatus: UInt8                  // Status of driver - 0 = in garage, 1 = flying lap, etc.
    var resultStatus: UInt8                  // Result status - 0 = invalid, 1 = inactive, etc.
    var pitLaneTimerActive: UInt8            // Pit lane timing, 0 = inactive, 1 = active
    var pitLaneTimeInLaneInMS: UInt16        // If active, the current time spent in the pit lane
    var pitStopTimerInMS: UInt16             // Time of the actual pit stop in milliseconds
    var pitStopShouldServePen: UInt8         // Whether the car should serve a penalty at this stop
    
    static let size = 57
    
    init(data: Data, offset: inout Int) {
        func read<T>(_ type: T.Type) -> T {
            let size = MemoryLayout<T>.size
            let value = data.subdata(in: offset..<offset+size).withUnsafeBytes { $0.load(as: T.self) }
            offset += size
            return value
        }
        
        lastLapTimeInMS = read(UInt32.self)
        currentLapTimeInMS = read(UInt32.self)
        sector1TimeInMS = read(UInt16.self)
        sector1TimeMinutes = read(UInt8.self)
        sector2TimeInMS = read(UInt16.self)
        sector2TimeMinutes = read(UInt8.self)
        deltaToCarInFrontInMS = read(UInt16.self)
        deltaToRaceLeaderInMS = read(UInt16.self)
        lapDistance = read(Float.self)
        totalDistance = read(Float.self)
        safetyCarDelta = read(Float.self)
        carPosition = read(UInt8.self)
        currentLapNum = read(UInt8.self)
        pitStatus = read(UInt8.self)
        numPitStops = read(UInt8.self)
        sector = read(UInt8.self)
        currentLapInvalid = read(UInt8.self)
        penalties = read(UInt8.self)
        totalWarnings = read(UInt8.self)
        cornerCuttingWarnings = read(UInt8.self)
        numUnservedDriveThroughPens = read(UInt8.self)
        numUnservedStopGoPens = read(UInt8.self)
        gridPosition = read(UInt8.self)
        driverStatus = read(UInt8.self)
        resultStatus = read(UInt8.self)
        pitLaneTimerActive = read(UInt8.self)
        pitLaneTimeInLaneInMS = read(UInt16.self)
        pitStopTimerInMS = read(UInt16.self)
        pitStopShouldServePen = read(UInt8.self)
    }
}

struct PacketLapData {
    var header: PacketHeader
    var lapData: [LapData] // Lap data for all cars (22 cars max)
    var timeTrialPBCarIdx: UInt8
    var timeTrialRivalCarIdx: UInt8
    
    init?(data: Data) {
        guard data.count >= PacketHeader.size else { return nil }
        
        header = PacketHeader(data: data)
        
        var offset = PacketHeader.size
        var lapDataArray: [LapData] = []
        
        // Parse lap data for all 22 cars
        for _ in 0..<22 {
            guard offset + LapData.size <= data.count else { return nil }
            let lap = LapData(data: data, offset: &offset)
            lapDataArray.append(lap)
        }
        
        lapData = lapDataArray
        
        guard offset + 2 <= data.count else { return nil }
        timeTrialPBCarIdx = data[offset]
        offset += 1
        timeTrialRivalCarIdx = data[offset]
    }
}

// MARK: - Car Status Data (Packet ID 7)
struct CarStatusData {
    var tractionControl: UInt8          // Traction control - 0 = off, 1 = medium, 2 = full
    var antiLockBrakes: UInt8           // 0 = off, 1 = on
    var fuelMix: UInt8                  // Fuel mix - 0 = lean, 1 = standard, 2 = rich, 3 = max
    var frontBrakeBias: UInt8           // Front brake bias (percentage)
    var pitLimiterStatus: UInt8         // Pit limiter status - 0 = off, 1 = on
    var fuelInTank: Float               // Current fuel mass
    var fuelCapacity: Float             // Fuel capacity
    var fuelRemainingLaps: Float        // Fuel remaining in terms of laps (value on MFD)
    var maxRPM: UInt16                  // Cars max RPM, point of rev limiter
    var idleRPM: UInt16                 // Cars idle RPM
    var maxGears: UInt8                 // Maximum number of gears
    var drsAllowed: UInt8               // 0 = not allowed, 1 = allowed
    var drsActivationDistance: UInt16   // 0 = DRS not available, non-zero - DRS will activate in [X] metres
    var actualTyreCompound: UInt8       // F1 Modern - 16 = C5, 17 = C4, 18 = C3, 19 = C2, 20 = C1
    var visualTyreCompound: UInt8       // F1 visual (can be different) - 16 = soft, 17 = medium, 18 = hard
    var tyresAgeLaps: UInt8             // Age in laps of the current set of tyres
    var vehicleFiaFlags: Int8           // -1 = invalid/unknown, 0 = none, 1 = green, 2 = blue, 3 = yellow
    var enginePowerICE: Float           // Engine power output of ICE (W)
    var enginePowerMGUK: Float          // Engine power output of MGU-K (W)
    var ersStoreEnergy: Float           // ERS energy store in Joules
    var ersDeployMode: UInt8            // ERS deployment mode, 0 = none, 1 = medium, etc.
    var ersHarvestedThisLapMGUK: Float  // ERS energy harvested this lap by MGU-K
    var ersHarvestedThisLapMGUH: Float  // ERS energy harvested this lap by MGU-H
    var ersDeployedThisLap: Float       // ERS energy deployed this lap
    var networkPaused: UInt8            // Whether the car is paused in a network game
    
    static let size = 58
    
    init(data: Data, offset: inout Int) {
        func read<T>(_ type: T.Type) -> T {
            let size = MemoryLayout<T>.size
            let value = data.subdata(in: offset..<offset+size).withUnsafeBytes { $0.load(as: T.self) }
            offset += size
            return value
        }
        
        tractionControl = read(UInt8.self)
        antiLockBrakes = read(UInt8.self)
        fuelMix = read(UInt8.self)
        frontBrakeBias = read(UInt8.self)
        pitLimiterStatus = read(UInt8.self)
        fuelInTank = read(Float.self)
        fuelCapacity = read(Float.self)
        fuelRemainingLaps = read(Float.self)
        maxRPM = read(UInt16.self)
        idleRPM = read(UInt16.self)
        maxGears = read(UInt8.self)
        drsAllowed = read(UInt8.self)
        drsActivationDistance = read(UInt16.self)
        actualTyreCompound = read(UInt8.self)
        visualTyreCompound = read(UInt8.self)
        tyresAgeLaps = read(UInt8.self)
        vehicleFiaFlags = read(Int8.self)
        enginePowerICE = read(Float.self)
        enginePowerMGUK = read(Float.self)
        ersStoreEnergy = read(Float.self)
        ersDeployMode = read(UInt8.self)
        ersHarvestedThisLapMGUK = read(Float.self)
        ersHarvestedThisLapMGUH = read(Float.self)
        ersDeployedThisLap = read(Float.self)
        networkPaused = read(UInt8.self)
    }
}

struct PacketCarStatusData {
    var header: PacketHeader
    var carStatusData: [CarStatusData] // Status data for all cars (22 cars max)
    
    init?(data: Data) {
        guard data.count >= PacketHeader.size else { return nil }
        
        header = PacketHeader(data: data)
        
        var offset = PacketHeader.size
        var statusArray: [CarStatusData] = []
        
        // Parse status for all 22 cars
        for _ in 0..<22 {
            guard offset + CarStatusData.size <= data.count else { return nil }
            let status = CarStatusData(data: data, offset: &offset)
            statusArray.append(status)
        }
        
        carStatusData = statusArray
    }
}

