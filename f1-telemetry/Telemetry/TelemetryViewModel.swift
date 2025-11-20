//
//  TelemetryViewModel.swift
//  f1-tracker
//
//  ViewModel for managing F1 telemetry state
//

import Foundation
import SwiftUI
import Combine
import SwiftData

struct TelemetryPoint: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

// MARK: - Safe Conversion Extension
extension Double {
    func safeInt() -> Int {
        if self.isNaN || self.isInfinite {
            return 0
        }
        if self > Double(Int.max) {
            return Int.max
        }
        if self < Double(Int.min) {
            return Int.min
        }
        return Int(self)
    }
}

@MainActor
class TelemetryViewModel: ObservableObject {
    private let historyLimit = 160
    private let weatherPersistInterval: TimeInterval = 20
    private let baseChassisMassKg: Double = 798
    private let driverMassKg: Double = 80
    // MARK: - Persistence Toggle
    private let persistenceEnabled = true // Persist sessions, laps, and telemetry traces
    
    // MARK: - Published Properties
    
    // Car Telemetry
    @Published var speed: Double = 0
    @Published var gear: Int = 0
    @Published var rpm: Double = 0
    @Published var maxRPM: Double = 15000
    @Published var throttle: Double = 0
    @Published var brake: Double = 0
    @Published var clutch: UInt8 = 0
    @Published var steer: Double = 0
    @Published var drsActive: Bool = false
    @Published var drsAvailable: Bool = false
    
    // Engine & Temperatures
    @Published var engineTemp: Double = 0
    @Published var tyreTempFL: Double = 0
    @Published var tyreTempFR: Double = 0
    @Published var tyreTempRL: Double = 0
    @Published var tyreTempRR: Double = 0

    // Inner tyre temperatures
    @Published var tyreInnerTempFL: Double = 0
    @Published var tyreInnerTempFR: Double = 0
    @Published var tyreInnerTempRL: Double = 0
    @Published var tyreInnerTempRR: Double = 0

    // Brake temperatures
    @Published var brakeTempFL: Double = 0
    @Published var brakeTempFR: Double = 0
    @Published var brakeTempRL: Double = 0
    @Published var brakeTempRR: Double = 0

    // Car Status
    @Published var fuelInTank: Double = 0
    @Published var fuelCapacity: Double = 110
    @Published var fuelRemainingLaps: Double = 0
    @Published var tyreCompound: String = "Unknown"
    @Published var tyreAge: Int = 0
    @Published var nextStrategyTyre: String = "TBD"
    @Published var ersStoreEnergy: Double = 0
    @Published var ersDeployMode: String = "None"

    // Motion (player car)
    @Published var gLat: Double = 0
    @Published var gLong: Double = 0
    @Published var gVert: Double = 0
    @Published var yaw: Double = 0
    @Published var pitch: Double = 0
    @Published var roll: Double = 0

    // World position (player car)
    @Published var worldX: Double = 0
    @Published var worldZ: Double = 0
    @Published var minWorldX: Double = Double.greatestFiniteMagnitude
    @Published var maxWorldX: Double = -Double.greatestFiniteMagnitude
    @Published var minWorldZ: Double = Double.greatestFiniteMagnitude
    @Published var maxWorldZ: Double = -Double.greatestFiniteMagnitude

    // Damage (player car)
    @Published var tyreWear: [Float] = [0,0,0,0]
    @Published var tyreDamage: [UInt8] = [0,0,0,0]
    @Published var brakeDamage: [UInt8] = [0,0,0,0]
    @Published var frontWingDamage: Int = 0
    @Published var rearWingDamage: Int = 0
    @Published var floorDamage: Int = 0
    @Published var diffuserDamage: Int = 0
    @Published var sidepodDamage: Int = 0
    @Published var gearBoxDamage: Int = 0
    @Published var engineDamagePercent: Int = 0
    @Published var wheelSlipFront: Double = 0
    @Published var wheelSlipRear: Double = 0
    @Published var handlingBalance: HandlingBalanceState = .neutral
    @Published var handlingConfidence: Double = 0
    @Published var lastPacketTimestamp: String = "00:00:00.000"
    
    var vehicleMassEstimateKg: Double {
        let minimumMass = baseChassisMassKg + driverMassKg
        let total = minimumMass + max(0, fuelInTank)
        return max(total, minimumMass)
    }
    
    // Lap Data
    @Published var currentLap: Int = 0
    @Published var position: Int = 0
    @Published var lastLapTime: String = "--:--.---"
    @Published var currentLapTime: String = "--:--.---"
    @Published var sector1Time: String = "--:--.---"
    @Published var sector2Time: String = "--:--.---"
    @Published var deltaToLeader: String = "+0.000"
    @Published var deltaToFront: String = "+0.000"
    @Published var deltaToBehind: String = "+0.000"
    @Published var lapDistance: Double = 0
    @Published var penaltiesSeconds: Int = 0
    @Published var warningsCount: Int = 0
    @Published var unservedDriveThrough: Int = 0
    @Published var unservedStopGo: Int = 0
    
    // Connection Status
    @Published var isConnected: Bool = false
    @Published var packetsReceived: Int = 0
    @Published var lastUpdateTime: Date = Date()
    @Published var localIPAddress: String = "Fetching..."
    @Published var port: UInt16 = 20777

    // Player
    @Published var playerCarIndex: Int = 0
    @Published var playerTeamId: UInt8?

    // Session Identifiers
    @Published var sessionUID: String = "No session"

    // History buffers for dashboard charts
    @Published private(set) var speedHistory: [TelemetryPoint] = []
    @Published private(set) var throttleHistory: [TelemetryPoint] = []
    @Published private(set) var brakeHistory: [TelemetryPoint] = []
    @Published private(set) var lateralGHistory: [TelemetryPoint] = []
    @Published private(set) var longitudinalGHistory: [TelemetryPoint] = []
    @Published private(set) var frontSlipHistory: [TelemetryPoint] = []
    @Published private(set) var rearSlipHistory: [TelemetryPoint] = []
    private var lapTelemetrySamples: [LapTelemetrySample] = []
    private var lapSectorTimes: [Int: SectorTimes] = [:]
    private var lapValidity: [Int: Bool] = [:]
    private var lastWeatherPersistDate: Date?

    // Session Info
    @Published var weather: UInt8 = 0 // 0 = clear
    @Published var trackTemp: Int = 0
    @Published var airTemp: Int = 0
    @Published var totalLapsSession: Int = 0
    @Published var timeLeft: Int = 0
    @Published var trackId: Int8 = -1
    @Published var sessionType: UInt8 = 0
    @Published var trackLength: Int = 0

    // Weather forecast (next 5 samples)
    @Published var weatherForecastNext: [UInt8] = []
    @Published var weatherForecastDetailed: [WeatherForecastRecord] = []
    @Published var safetyCarStatus: UInt8 = 0
    
    // Participants
    @Published var participants: [ParticipantData] = []
    @Published var activeCars: Int = 0

    // Loading
    private let telemetryListener: TelemetryListener
    private var connectionCheckTimer: Timer?
    private let context: ModelContext
    
    // Keep track of sessions already stored to avoid duplicate inserts
    private var persistedSessions: Set<UInt64> = []
    
    init(port: UInt16 = 20777, context: ModelContext? = nil) {
        print("🏁 TelemetryViewModel initializing...")
        self.context = context ?? PersistenceController.shared.modelContainer.mainContext
        self.port = port
        telemetryListener = TelemetryListener(port: port)
        setupCallbacks()
        startConnectionMonitoring()
        getLocalIPAddress()
        print("✅ TelemetryViewModel initialized")
    }
    
    // MARK: - Setup
    
    private func setupCallbacks() {
        print("🔧 Setting up telemetry callbacks...")
        
        // Handle Car Telemetry packets
        telemetryListener.onTelemetryReceived = { [weak self] packet in
            print("📞 Car Telemetry callback triggered!")
            guard let self = self else {
                print("❌ Self is nil in telemetry callback")
                return
            }
            let playerIndex = Int(packet.header.playerCarIndex)
            print("   Player index: \(playerIndex), data count: \(packet.carTelemetryData.count)")
            guard playerIndex < packet.carTelemetryData.count else {
                print("❌ Player index out of bounds!")
                return
            }
            
            let telemetry = packet.carTelemetryData[playerIndex]
            
            DispatchQueue.main.async {
                print("🔄 Updating UI with telemetry data...")
                self.speed = Double(telemetry.speed)
                self.gear = Int(telemetry.gear)
                self.rpm = Double(telemetry.engineRPM)
                self.throttle = Double(telemetry.throttle) * 100
                self.brake = Double(telemetry.brake) * 100
                self.clutch = UInt8(telemetry.clutch)
                self.steer = Double(telemetry.steer)
                self.drsActive = telemetry.drs == 1
                self.engineTemp = Double(telemetry.engineTemperature)
                
                // Tyre temperatures
                if telemetry.tyresSurfaceTemperature.count == 4 {
                    self.tyreTempRL = Double(telemetry.tyresSurfaceTemperature[0])
                    self.tyreTempRR = Double(telemetry.tyresSurfaceTemperature[1])
                    self.tyreTempFL = Double(telemetry.tyresSurfaceTemperature[2])
                    self.tyreTempFR = Double(telemetry.tyresSurfaceTemperature[3])

                    // Inner tyre temps
                    if telemetry.tyresInnerTemperature.count == 4 {
                        self.tyreInnerTempRL = Double(telemetry.tyresInnerTemperature[0])
                        self.tyreInnerTempRR = Double(telemetry.tyresInnerTemperature[1])
                        self.tyreInnerTempFL = Double(telemetry.tyresInnerTemperature[2])
                        self.tyreInnerTempFR = Double(telemetry.tyresInnerTemperature[3])
                    }

                    // Brake temps (celsius as UInt16)
                    if telemetry.brakesTemperature.count == 4 {
                        self.brakeTempRL = Double(telemetry.brakesTemperature[0])
                        self.brakeTempRR = Double(telemetry.brakesTemperature[1])
                        self.brakeTempFL = Double(telemetry.brakesTemperature[2])
                        self.brakeTempFR = Double(telemetry.brakesTemperature[3])
                    }
                }
                
                self.lastUpdateTime = Date()
                let previousPackets = self.packetsReceived
                self.packetsReceived = self.telemetryListener.packetsReceived
                self.updateSessionInfo(from: packet.header)
                self.updateLastPacketTimestamp()
                self.recordInputSnapshot()
                self.captureLapTelemetrySample(
                    speed: Double(telemetry.speed),
                    throttle: Double(telemetry.throttle) * 100,
                    brake: Double(telemetry.brake) * 100,
                    gear: Int(telemetry.gear),
                    steer: Double(telemetry.steer),
                    rpm: Double(telemetry.engineRPM),
                    lateralG: self.gLat,
                    longitudinalG: self.gLong,
                    frontSlip: self.wheelSlipFront,
                    rearSlip: self.wheelSlipRear
                )
                
                // Log first packet received
                if previousPackets == 0 && self.packetsReceived > 0 {
                    print("🎮 First Car Telemetry packet received!")
                    print("   Speed: \(telemetry.speed) km/h, Gear: \(telemetry.gear), RPM: \(telemetry.engineRPM)")
                }
                
                print("✅ UI update complete")
                self.objectWillChange.send()
            }
        }
        
        // Handle Lap Data packets
        telemetryListener.onLapDataReceived = { [weak self] packet in
            print("📞 Lap Data callback triggered!")
            guard let self = self else {
                print("❌ Self is nil in lap data callback")
                return
            }
            let playerIndex = Int(packet.header.playerCarIndex)
            print("   Player index: \(playerIndex), data count: \(packet.lapData.count)")
            guard playerIndex < packet.lapData.count else {
                print("❌ Player index out of bounds!")
                return
            }

            let lapData = packet.lapData[playerIndex]
            
            DispatchQueue.main.async {
                print("🔄 Updating UI with lap data...")
                let previousLap = self.currentLap
                let latestLapNumber = Int(lapData.currentLapNum)
                self.currentLap = latestLapNumber
                self.position = Int(lapData.carPosition)
                self.lapDistance = Double(lapData.lapDistance)
                self.penaltiesSeconds = Int(lapData.penalties)
                self.warningsCount = Int(lapData.totalWarnings)
                self.unservedDriveThrough = Int(lapData.numUnservedDriveThroughPens)
                self.unservedStopGo = Int(lapData.numUnservedStopGoPens)
                
                self.recordSectorTimes(from: lapData)
                
                // Format times
                self.lastLapTime = self.formatLapTime(lapData.lastLapTimeInMS)
                self.currentLapTime = self.formatLapTime(lapData.currentLapTimeInMS)
                self.sector1Time = self.formatSectorTime(lapData.sector1TimeInMS, minutes: lapData.sector1TimeMinutes)
                self.sector2Time = self.formatSectorTime(lapData.sector2TimeInMS, minutes: lapData.sector2TimeMinutes)
                
                // Delta to leader
                let leaderTotalMs = Int(lapData.deltaToRaceLeaderMinutes) * 60000 + Int(lapData.deltaToRaceLeaderInMS)
                self.deltaToLeader = self.formattedGap(fromMilliseconds: leaderTotalMs)

                // Delta to car in front
                let frontTotalMs = Int(lapData.deltaToCarInFrontMinutes) * 60000 + Int(lapData.deltaToCarInFrontInMS)
                self.deltaToFront = self.formattedGap(fromMilliseconds: frontTotalMs)
                
                // Delta to car behind
                self.deltaToBehind = self.gapToCarBehind(
                    in: packet.lapData,
                    playerPosition: Int(lapData.carPosition),
                    playerLeaderMs: leaderTotalMs
                )
                
                self.updateSessionInfo(from: packet.header)
                self.updateLastPacketTimestamp()
                
                // Log lap changes
                if previousLap > 0 && latestLapNumber != previousLap {
                    let completedLapNumber = Int16(previousLap)
                    print("🏁 Lap \(completedLapNumber) completed! Last lap time: \(self.lastLapTime)")
                    print("   Now on lap \(latestLapNumber), Position: P\(self.position)")
                    let sectorSnapshot = self.lapSectorTimes.removeValue(forKey: previousLap)
                    let lapValidSnapshot = self.lapValidity.removeValue(forKey: previousLap) ?? true
                    self.persistLapSummary(
                        lapData,
                        header: packet.header,
                        completedLapNumber: completedLapNumber,
                        sectorTimes: sectorSnapshot,
                        lapIsValid: lapValidSnapshot
                    )
                }
                
                print("✅ UI update complete - Lap: \(self.currentLap), Position: P\(self.position)")
                self.objectWillChange.send()
            }
        }
        
        // Handle Car Status packets
        telemetryListener.onCarStatusReceived = { [weak self] packet in
            print("📞 Car Status callback triggered!")
            guard let self = self else {
                print("❌ Self is nil in car status callback")
                return
            }
            let playerIndex = Int(packet.header.playerCarIndex)
            print("   Player index: \(playerIndex), data count: \(packet.carStatusData.count)")
            guard playerIndex < packet.carStatusData.count else {
                print("❌ Player index out of bounds!")
                return
            }
            
            let status = packet.carStatusData[playerIndex]
            
            DispatchQueue.main.async {
                print("🔄 Updating UI with car status...")
                let previousFuel = self.fuelInTank
                self.fuelInTank = Double(status.fuelInTank)
                self.fuelCapacity = Double(status.fuelCapacity)
                self.fuelRemainingLaps = Double(status.fuelRemainingLaps)
                self.maxRPM = Double(status.maxRPM)
                self.tyreAge = Int(status.tyresAgeLaps)
                self.tyreCompound = self.getTyreCompoundName(status.visualTyreCompound)
                self.drsAvailable = status.drsAllowed == 1
                self.ersStoreEnergy = Double(status.ersStoreEnergy)
                self.ersDeployMode = self.getERSModeName(status.ersDeployMode)
                
                self.updateSessionInfo(from: packet.header)
                self.updateLastPacketTimestamp()
                
                // Log first car status packet
                if previousFuel == 0 && self.fuelInTank > 0 {
                    print("⛽ First Car Status packet received!")
                    print("   Fuel: \(String(format: "%.1f", self.fuelInTank))kg, Tyres: \(self.tyreCompound) (\(self.tyreAge) laps)")
                }
                
                print("✅ UI update complete - Fuel: \(self.fuelInTank)kg, Tyres: \(self.tyreCompound)")
                self.objectWillChange.send()
            }
        }

        // Handle Session packets
        telemetryListener.onSessionReceived = { [weak self] packet in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.weather = packet.weather
                self.trackTemp = Int(packet.trackTemperature)
                self.airTemp = Int(packet.airTemperature)
                self.totalLapsSession = Int(packet.totalLaps)
                self.timeLeft = Int(packet.timeLeft)
                self.trackId = packet.trackId
                self.trackLength = Int(packet.trackLength)
                self.sessionType = packet.sessionType
                self.safetyCarStatus = packet.safetyCarStatus

                // Update weather forecast samples
                if !packet.weatherForecastSamples.isEmpty {
                    // Take first 5 samples
                    self.weatherForecastNext = packet.weatherForecastSamples.prefix(5).map { $0.weather }
                    self.weatherForecastDetailed = self.forecastRecords(from: packet)
                } else {
                    self.weatherForecastNext = []
                    self.weatherForecastDetailed = []
                }
                self.updateSessionInfo(from: packet.header)
                self.updateLastPacketTimestamp()
                self.persistSessionIfNeeded(header: packet.header)
                self.updateSessionRecord(
                    uid: packet.header.sessionUID,
                    weather: packet.weather,
                    trackTemp: packet.trackTemperature,
                    airTemp: packet.airTemperature,
                    totalLaps: packet.totalLaps
                )
                self.persistWeatherSample(packet: packet)
            }
        }

        // Handle Motion packets
        telemetryListener.onMotionReceived = { [weak self] packet in
            guard let self = self else { return }
            let playerIndex = Int(packet.header.playerCarIndex)
            guard playerIndex < packet.carMotionData.count else { return }
            let m = packet.carMotionData[playerIndex]
            DispatchQueue.main.async {
                self.gLat = Double(m.gForceLateral)
                self.gLong = Double(m.gForceLongitudinal)
                self.gVert = Double(m.gForceVertical)
                self.yaw = Double(m.yaw)
                self.pitch = Double(m.pitch)
                self.roll = Double(m.roll)
                // Update world position
                self.worldX = Double(m.worldPositionX)
                self.worldZ = Double(m.worldPositionZ)
                if packet.wheelSlip.count == 4 {
                    let rear = (Double(packet.wheelSlip[0]) + Double(packet.wheelSlip[1])) / 2.0
                    let front = (Double(packet.wheelSlip[2]) + Double(packet.wheelSlip[3])) / 2.0
                    self.updateHandlingBalance(frontSlip: front, rearSlip: rear)
                } else {
                    self.updateHandlingBalance(frontSlip: 0, rearSlip: 0)
                }
                self.updateSessionInfo(from: packet.header)
                self.updateLastPacketTimestamp()
                self.recordGForceSnapshot()
            }
        }

        // Participants
        telemetryListener.onParticipantsReceived = { [weak self] packet in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.activeCars = Int(packet.numActiveCars)
                self.participants = packet.participants
                let playerIndex = Int(packet.header.playerCarIndex)
                self.playerCarIndex = playerIndex
                self.updatePlayerTeam(with: playerIndex)
            }
        }

        // Damage
        telemetryListener.onDamageReceived = { [weak self] packet in
            guard let self = self else { return }
            let idx = Int(packet.header.playerCarIndex)
            guard idx < packet.carDamageData.count else { return }
            let dmg = packet.carDamageData[idx]
            DispatchQueue.main.async {
                self.tyreWear = dmg.tyresWear
                self.tyreDamage = dmg.tyresDamage
                self.brakeDamage = dmg.brakesDamage
                self.frontWingDamage = Int(dmg.frontLeftWingDamage + dmg.frontRightWingDamage)/2
                self.rearWingDamage = Int(dmg.rearWingDamage)
                self.floorDamage = Int(dmg.floorDamage)
                self.diffuserDamage = Int(dmg.diffuserDamage)
                self.sidepodDamage = Int(dmg.sidepodDamage)
                self.gearBoxDamage = Int(dmg.gearBoxDamage)
                self.engineDamagePercent = Int(dmg.engineDamage)
            }
        }

        telemetryListener.onFinalClassificationReceived = { [weak self] packet in
            DispatchQueue.main.async {
                self?.persistFinalClassification(packet)
            }
        }
    }
    
    // MARK: - Public Methods
    func startListening() {
        print("🚀 Starting telemetry listener...")
        print("📡 Listening on port \(port)")
        print("🌐 Your device IP: \(localIPAddress)")
        print("💡 Configure F1 game UDP settings to match these values")
        telemetryListener.startListening()
    }
    
    func stopListening() {
        telemetryListener.stopListening()
    }
    
    func resetHistories() {
        speedHistory.removeAll()
        throttleHistory.removeAll()
        brakeHistory.removeAll()
        lateralGHistory.removeAll()
        longitudinalGHistory.removeAll()
        frontSlipHistory.removeAll()
        rearSlipHistory.removeAll()
    }
    
    // MARK: - Private Helpers
    private func startConnectionMonitoring() {
        connectionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let timeSinceUpdate = Date().timeIntervalSince(self.lastUpdateTime)
                let wasConnected = self.isConnected
                let nowConnected = timeSinceUpdate < 3.0 && self.telemetryListener.isListening
                
                if wasConnected != nowConnected {
                    if nowConnected {
                        print("✅ Telemetry CONNECTED - Receiving data from F1 game")
                        print("📊 Packets received: \(self.packetsReceived)")
                    } else {
                        print("⚠️ Telemetry DISCONNECTED - No data received")
                        print("💡 Make sure F1 game UDP settings match: IP \(self.localIPAddress), Port \(self.port)")
                    }
                }
                self.isConnected = nowConnected
            }
        }
    }
    
    // MARK: - Formatting
    private func formatLapTime(_ milliseconds: UInt32) -> String {
        guard milliseconds > 0 else { return "--:--.---" }
        
        let totalSeconds = Double(milliseconds) / 1000.0
        let minutes = Int(totalSeconds / 60)
        let seconds = totalSeconds.truncatingRemainder(dividingBy: 60)
        
        return String(format: "%d:%06.3f", minutes, seconds)
    }
    
    private func formatSectorTime(_ milliseconds: UInt16, minutes: UInt8) -> String {
        guard milliseconds > 0 || minutes > 0 else { return "--:--.---" }
        
        let totalSeconds = Double(minutes) * 60.0 + Double(milliseconds) / 1000.0
        let mins = Int(totalSeconds / 60)
        let secs = totalSeconds.truncatingRemainder(dividingBy: 60)
        
        return String(format: "%d:%06.3f", mins, secs)
    }
    
    private func getTyreCompoundName(_ compound: UInt8) -> String {
        switch compound {
        case 16: return "Soft"
        case 17: return "Medium"
        case 18: return "Hard"
        case 7: return "Inter"
        case 8: return "Wet"
        default: return "Unknown"
        }
    }
    
    private func getERSModeName(_ mode: UInt8) -> String {
        switch mode {
        case 0: return "None"
        case 1: return "Medium"
        case 2: return "Hotlap"
        case 3: return "Overtake"
        default: return "Unknown"
        }
    }

    // MARK: - Session Info
    private func updateSessionInfo(from header: PacketHeader) {
        // Update player car index
        playerCarIndex = Int(header.playerCarIndex)
        let newSessionUID = String(header.sessionUID)
        if sessionUID != newSessionUID && newSessionUID != "0" {
            if sessionUID != "No session" {
                print("🔄 Session changed!")
                print("   Old: \(sessionUID)")
                print("   New: \(newSessionUID)")
            } else {
                print("🎮 Session started: \(newSessionUID)")
            }
            sessionUID = newSessionUID
            lapTelemetrySamples.removeAll()
            lapSectorTimes.removeAll()
            lapValidity.removeAll()
        }
        updatePlayerTeam()
    }

    private func updatePlayerTeam(with playerIndex: Int? = nil) {
        let index = playerIndex ?? playerCarIndex
        guard participants.indices.contains(index) else { return }
        let detectedTeam = participants[index].teamId
        if playerTeamId != detectedTeam {
            playerTeamId = detectedTeam
        }
    }
    
    private func updateLastPacketTimestamp() {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: now)
        
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        let seconds = components.second ?? 0
        let milliseconds = (components.nanosecond ?? 0) / 1_000_000
        
        lastPacketTimestamp = String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
    }
    
    private func captureLapTelemetrySample(
        speed: Double,
        throttle: Double,
        brake: Double,
        gear: Int,
        steer: Double,
        rpm: Double,
        lateralG: Double,
        longitudinalG: Double,
        frontSlip: Double,
        rearSlip: Double
    ) {
        guard persistenceEnabled else { return }
        guard trackLength > 0 else { return }
        let lapProgress = max(0, min(1, lapDistance / Double(trackLength)))
        let sample = LapTelemetrySample(
            distance: lapProgress,
            speed: speed,
            throttle: throttle,
            brake: brake,
            gear: Double(gear),
            rpm: rpm,
            steer: steer,
            lateralG: lateralG,
            longitudinalG: longitudinalG,
            frontSlip: frontSlip,
            rearSlip: rearSlip
        )
        lapTelemetrySamples.append(sample)
    }
    
    private func recordSectorTimes(from lapData: LapData) {
        let lapIndex = Int(lapData.currentLapNum)
        guard lapIndex > 0 else { return }
        
        var snapshot = lapSectorTimes[lapIndex] ?? SectorTimes()
        let s1 = combinedSectorTime(minutes: lapData.sector1TimeMinutes, milliseconds: lapData.sector1TimeInMS)
        if s1 > 0 {
            snapshot.sector1 = s1
        }
        let s2 = combinedSectorTime(minutes: lapData.sector2TimeMinutes, milliseconds: lapData.sector2TimeInMS)
        if s2 > 0 {
            snapshot.sector2 = s2
        }
        lapSectorTimes[lapIndex] = snapshot
        lapValidity[lapIndex] = (lapData.currentLapInvalid == 0)
    }
    
    private func combinedSectorTime(minutes: UInt8, milliseconds: UInt16) -> Int32 {
        Int32(minutes) * 60_000 + Int32(milliseconds)
    }
    
    private func formattedGap(fromMilliseconds value: Int) -> String {
        guard value > 0 else { return "+0.000" }
        return String(format: "+%.3f", Double(value) / 1000.0)
    }
    
    private func gapToCarBehind(
        in lapDataArray: [LapData],
        playerPosition: Int,
        playerLeaderMs: Int
    ) -> String {
        let targetPosition = playerPosition + 1
        guard targetPosition <= 22 else { return "+0.000" }
        guard let carBehind = lapDataArray.first(where: { Int($0.carPosition) == targetPosition }) else {
            return "+0.000"
        }
        let behindLeaderMs = Int(carBehind.deltaToRaceLeaderMinutes) * 60000 + Int(carBehind.deltaToRaceLeaderInMS)
        let gapMs = behindLeaderMs - playerLeaderMs
        guard gapMs > 0 else { return "+0.000" }
        return formattedGap(fromMilliseconds: gapMs)
    }

    private func forecastRecords(from packet: PacketSessionData) -> [WeatherForecastRecord] {
        packet.weatherForecastSamples.prefix(8).map {
            WeatherForecastRecord(
                timeOffsetMinutes: Int($0.timeOffset),
                weatherCode: $0.weather,
                trackTemp: $0.trackTemperature,
                airTemp: $0.airTemperature
            )
        }
    }

    private func updateHandlingBalance(frontSlip: Double, rearSlip: Double) {
        wheelSlipFront = frontSlip
        wheelSlipRear = rearSlip
        let slipDelta = frontSlip - rearSlip
        let steerMagnitude = abs(steer)
        let gMagnitude = abs(gLat)
        let threshold = 0.05

        var state: HandlingBalanceState = .neutral
        if steerMagnitude > 0.08 {
            if slipDelta > threshold {
                state = .understeer
            } else if slipDelta < -threshold {
                state = .oversteer
            }
        }
        handlingBalance = state

        let normalizedSlip = min(1.0, max(0, abs(slipDelta) / 0.7))
        let steeringFactor = min(1.0, steerMagnitude / 0.9)
        let gripFactor = min(1.0, max(0.2, gMagnitude / 2.8))
        handlingConfidence = normalizedSlip * steeringFactor * gripFactor
        recordHandlingSnapshot(frontSlip: frontSlip, rearSlip: rearSlip)
    }
    
    private func persistSessionIfNeeded(header: PacketHeader) {
        guard persistenceEnabled else { return }
        guard header.sessionUID != 0 else { return }
        let uid = header.sessionUID
        if persistedSessions.contains(uid) { return }
        do {
            let fetch = FetchDescriptor<RaceSession>(predicate: #Predicate { $0.sessionUID == uid })
            let results = try context.fetch(fetch)
            if results.isEmpty {
                let session = RaceSession(
                    sessionUID: uid,
                    sessionType: Int16(sessionType),
                    trackId: Int16(trackId),
                    weatherCode: Int16(weather),
                    trackTemperature: Int16(trackTemp),
                    airTemperature: Int16(airTemp),
                    totalLapsPlanned: Int16(totalLapsSession)
                )
                context.insert(session)
                try context.save()
                persistedSessions.insert(uid)
            } else {
                persistedSessions.insert(uid)
            }
        } catch {
            print("❌ Failed to persist session: \(error)")
        }
    }

    private func persistWeatherSample(packet: PacketSessionData) {
        guard persistenceEnabled else { return }
        guard packet.header.sessionUID != 0 else { return }
        let now = Date()
        if let last = lastWeatherPersistDate, now.timeIntervalSince(last) < weatherPersistInterval {
            return
        }
        guard let session = ensureSession(for: packet.header.sessionUID) else { return }
        let records = forecastRecords(from: packet)
        let sample = SessionWeatherSample(
            session: session,
            sessionTime: Double(packet.header.sessionTime),
            timeLeft: Int32(packet.timeLeft),
            weatherCode: packet.weather,
            trackTemperature: Int16(packet.trackTemperature),
            airTemperature: Int16(packet.airTemperature),
            safetyCarStatus: packet.safetyCarStatus,
            forecast: records
        )
        context.insert(sample)
        do {
            try context.save()
            lastWeatherPersistDate = now
        } catch {
            print("⚠️ Failed to persist weather sample: \(error)")
        }
    }
    
    private func updateSessionRecord(
        uid: UInt64,
        weather: UInt8,
        trackTemp: Int8,
        airTemp: Int8,
        totalLaps: UInt8
    ) {
        guard persistenceEnabled else { return }
        guard uid != 0 else { return }
        
        do {
            let fetch = FetchDescriptor<RaceSession>(predicate: #Predicate { $0.sessionUID == uid })
            if let session = try context.fetch(fetch).first {
                session.weatherCode = Int16(weather)
                session.trackTemperature = Int16(trackTemp)
                session.airTemperature = Int16(airTemp)
                session.totalLapsPlanned = Int16(totalLaps)
                try context.save()
            }
        } catch {
            print("⚠️ Failed to update session metadata: \(error)")
        }
    }
    
    private func getLocalIPAddress() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            var address: String = "Unable to get IP"
            var fallbackAddress: String? = nil
            
            // Get list of all interfaces on the local machine:
            var ifaddr: UnsafeMutablePointer<ifaddrs>?
            guard getifaddrs(&ifaddr) == 0 else {
                print("❌ Failed to get network interfaces")
                DispatchQueue.main.async {
                    self?.localIPAddress = address
                }
                return
            }
            guard let firstAddr = ifaddr else {
                print("❌ No network interfaces found")
                DispatchQueue.main.async {
                    self?.localIPAddress = address
                }
                return
            }
            
            print("🔍 Scanning network interfaces for IP address...")
            
            // For each interface ...
            for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
                let interface = ifptr.pointee
                
                // Check for IPv4 interface:
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) {
                    
                    // Check interface name:
                    let name = String(cString: interface.ifa_name)
                    if name == "en0" || name == "en1" || name.hasPrefix("en") || name == "pdp_ip0" {
                        
                        // Convert interface address to a human readable string:
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        let foundAddress = String(cString: hostname)
                        
                        print("📱 Found IP on \(name): \(foundAddress)")
                        
                        // Check if it's a valid IP and not 0.0.0.0
                        if !foundAddress.isEmpty && foundAddress != "0.0.0.0" {
                            // Prefer 192.x.x.x addresses (typical local network)
                            if foundAddress.hasPrefix("192.") {
                                address = foundAddress
                                print("✅ Selected 192.x IP: \(address)")
                                break
                            } else if fallbackAddress == nil {
                                // Store as fallback if no 192.x address is found
                                fallbackAddress = foundAddress
                                print("💾 Stored fallback IP: \(foundAddress)")
                            }
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
            
            // If we didn't find a 192.x address, use the fallback
            if address == "Unable to get IP" && fallbackAddress != nil {
                address = fallbackAddress!
                print("⚠️ Using fallback IP: \(address)")
            }
            
            print("📡 Final IP address: \(address)")
            
            DispatchQueue.main.async {
                self?.localIPAddress = address
            }
        }
    }

    // Lap Summary
    private func persistLapSummary(
        _ lapData: LapData,
        header: PacketHeader,
        completedLapNumber: Int16,
        sectorTimes: SectorTimes?,
        lapIsValid: Bool
    ) {
        guard persistenceEnabled else { return }
        // Ensure we have a valid session UID
        guard header.sessionUID != 0 else { return }
        guard let session = ensureSession(for: header.sessionUID) else { return }
        
        // 2. Build LapSummary from the supplied LapData
        let lapTime = Int32(lapData.lastLapTimeInMS)
        guard lapTime > 0 else {
            print("⚠️ Skipping lap save: lap time was 0 (lap \(completedLapNumber))")
            return
        }
        
        var s1 = sectorTimes?.sector1 ?? 0
        var s2 = sectorTimes?.sector2 ?? 0
        
        if s1 == 0 {
            s1 = combinedSectorTime(minutes: lapData.sector1TimeMinutes, milliseconds: lapData.sector1TimeInMS)
        }
        if s2 == 0 {
            s2 = combinedSectorTime(minutes: lapData.sector2TimeMinutes, milliseconds: lapData.sector2TimeInMS)
        }
        
        let rawS3 = lapTime - s1 - s2
        let s3 = rawS3 >= 0 ? rawS3 : max(lapTime - s1, 0)
        let summary = LapSummary(session: session,
                                 vehicleIndex: Int16(header.playerCarIndex),
                                 lapNumber: completedLapNumber,
                                 lapTimeMS: lapTime,
                                 s1: s1,
                                 s2: s2,
                                 s3: s3,
                                 valid: lapIsValid)
        
        if !lapTelemetrySamples.isEmpty {
            let orderedSamples = lapTelemetrySamples.sorted { $0.distance < $1.distance }
            let trace = LapTelemetryTrace(lap: summary, samples: orderedSamples)
            summary.telemetryTrace = trace
            context.insert(trace)
        }
        lapTelemetrySamples.removeAll()
        
        // 3. Persist
        context.insert(summary)
        do {
            try context.save()
            print("💾 Saved LapSummary for lap #\(completedLapNumber) (UID: \(header.sessionUID))")
        } catch {
            print("❌ Failed saving LapSummary: \(error)")
        }
    }

    private func ensureSession(for uid: UInt64) -> RaceSession? {
        do {
            let fetch = FetchDescriptor<RaceSession>(predicate: #Predicate { $0.sessionUID == uid })
            if let session = try context.fetch(fetch).first {
                persistedSessions.insert(uid)
                return session
            }
            let session = RaceSession(
                sessionUID: uid,
                sessionType: Int16(self.sessionType),
                trackId: Int16(self.trackId),
                weatherCode: Int16(self.weather),
                trackTemperature: Int16(self.trackTemp),
                airTemperature: Int16(self.airTemp),
                totalLapsPlanned: Int16(self.totalLapsSession)
            )
            context.insert(session)
            try context.save()
            persistedSessions.insert(uid)
            return session
        } catch {
            print("⚠️ Failed to ensure session exists: \(error)")
            return nil
        }
    }

    private func persistFinalClassification(_ packet: PacketFinalClassificationData) {
        guard persistenceEnabled else { return }
        guard let session = ensureSession(for: packet.header.sessionUID) else { return }

        do {
            let existingDescriptor = FetchDescriptor<SessionClassification>()
            let existingEntries = try context.fetch(existingDescriptor).filter {
                $0.session?.sessionUID == session.sessionUID
            }
            for entry in existingEntries {
                if let stints = entry.stints {
                    stints.forEach { context.delete($0) }
                }
                context.delete(entry)
            }

            var newEntries: [SessionClassification] = []
            for (vehicleIndex, classification) in packet.classificationData.enumerated() {
                guard classification.numLaps > 0 || classification.resultStatus > 0 else { continue }
                let participant = participants.indices.contains(vehicleIndex) ? participants[vehicleIndex] : nil
                let driverName = participant?.name ?? "Car #\(vehicleIndex + 1)"
                let teamId = participant?.teamId ?? 255
                let entry = SessionClassification(
                    session: session,
                    vehicleIndex: Int16(vehicleIndex),
                    driverName: driverName,
                    teamId: teamId,
                    position: classification.position,
                    numLaps: classification.numLaps,
                    gridPosition: classification.gridPosition,
                    points: classification.points,
                    numPitStops: classification.numPitStops,
                    resultStatus: classification.resultStatus,
                    bestLapTimeMS: classification.bestLapTimeInMS,
                    totalRaceTimeSeconds: classification.totalRaceTime,
                    penaltiesTime: classification.penaltiesTime,
                    numPenalties: classification.numPenalties
                )

                let arraysCount = min(classification.tyreStintsActual.count,
                                      min(classification.tyreStintsVisual.count, classification.tyreStintsEndLaps.count))
                let stintCount = min(Int(classification.numTyreStints), arraysCount)
                if stintCount > 0 {
                    var stintEntries: [SessionStint] = []
                    for stintIndex in 0..<stintCount {
                        guard stintIndex < classification.tyreStintsActual.count,
                              stintIndex < classification.tyreStintsVisual.count,
                              stintIndex < classification.tyreStintsEndLaps.count else { break }
                        let stint = SessionStint(
                            classification: entry,
                            stintIndex: UInt8(stintIndex),
                            actualCompound: classification.tyreStintsActual[stintIndex],
                            visualCompound: classification.tyreStintsVisual[stintIndex],
                            endLap: classification.tyreStintsEndLaps[stintIndex]
                        )
                        stintEntries.append(stint)
                        context.insert(stint)
                    }
                    entry.stints = stintEntries
                }

                context.insert(entry)
                newEntries.append(entry)
            }
            session.classifications = newEntries
            try context.save()
            print("💾 Final classification stored for session \(session.sessionUID)")
        } catch {
            print("⚠️ Failed to persist final classification: \(error)")
        }
    }
    
    deinit {
        connectionCheckTimer?.invalidate()
        let listener = telemetryListener
        Task { @MainActor in
            listener.stopListening()
        }
    }
}

// MARK: - History helpers
extension TelemetryViewModel {
    private func recordInputSnapshot() {
        let timestamp = Date()
        appendHistory(&speedHistory, value: speed, timestamp: timestamp)
        appendHistory(&throttleHistory, value: throttle, timestamp: timestamp)
        appendHistory(&brakeHistory, value: brake, timestamp: timestamp)
    }
    
    private func recordGForceSnapshot() {
        let timestamp = Date()
        appendHistory(&lateralGHistory, value: gLat, timestamp: timestamp)
        appendHistory(&longitudinalGHistory, value: gLong, timestamp: timestamp)
    }
    
    private func recordHandlingSnapshot(frontSlip: Double, rearSlip: Double) {
        let timestamp = Date()
        appendHistory(&frontSlipHistory, value: frontSlip, timestamp: timestamp)
        appendHistory(&rearSlipHistory, value: rearSlip, timestamp: timestamp)
    }
    
    private func appendHistory(_ history: inout [TelemetryPoint], value: Double, timestamp: Date) {
        guard !value.isNaN, !value.isInfinite else { return }
        history.append(TelemetryPoint(timestamp: timestamp, value: value))
        if history.count > historyLimit {
            history.removeFirst(history.count - historyLimit)
        }
    }
}

private struct SectorTimes {
    var sector1: Int32 = 0
    var sector2: Int32 = 0
}

enum HandlingBalanceState: String {
    case neutral
    case understeer
    case oversteer

    var displayName: String {
        switch self {
        case .neutral: return "Neutral"
        case .understeer: return "Understeer"
        case .oversteer: return "Oversteer"
        }
    }
}

