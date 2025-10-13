//
//  TelemetryViewModel.swift
//  f1-tracker
//
//  ViewModel for managing F1 telemetry state
//

import Foundation
import SwiftUI
import Combine

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

class TelemetryViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Car Telemetry
    @Published var speed: Double = 0
    @Published var gear: Int = 0
    @Published var rpm: Double = 0
    @Published var maxRPM: Double = 15000
    @Published var throttle: Double = 0
    @Published var brake: Double = 0
    @Published var steer: Double = 0
    @Published var drsActive: Bool = false
    @Published var drsAvailable: Bool = false
    
    // Engine & Temperatures
    @Published var engineTemp: Double = 0
    @Published var tyreTempFL: Double = 0
    @Published var tyreTempFR: Double = 0
    @Published var tyreTempRL: Double = 0
    @Published var tyreTempRR: Double = 0
    
    // Lap Data
    @Published var currentLap: Int = 0
    @Published var position: Int = 0
    @Published var lastLapTime: String = "--:--.---"
    @Published var currentLapTime: String = "--:--.---"
    @Published var sector1Time: String = "--:--.---"
    @Published var sector2Time: String = "--:--.---"
    @Published var deltaToLeader: String = "+0.000"
    @Published var lapDistance: Double = 0
    
    // Car Status
    @Published var fuelInTank: Double = 0
    @Published var fuelCapacity: Double = 110
    @Published var fuelRemainingLaps: Double = 0
    @Published var tyreCompound: String = "Unknown"
    @Published var tyreAge: Int = 0
    @Published var ersStoreEnergy: Double = 0
    @Published var ersDeployMode: String = "None"
    
    // Connection Status
    @Published var isConnected: Bool = false
    @Published var packetsReceived: Int = 0
    @Published var lastUpdateTime: Date = Date()
    @Published var localIPAddress: String = "Fetching..."
    @Published var port: UInt16 = 20777
    @Published var sessionUID: String = "No session"
    @Published var lastPacketTimestamp: String = "00:00:00.000"
    
    private let telemetryListener: TelemetryListener
    private var connectionCheckTimer: Timer?
    
    init(port: UInt16 = 20777) {
        print("🏁 TelemetryViewModel initializing...")
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
                self.steer = Double(telemetry.steer)
                self.drsActive = telemetry.drs == 1
                self.engineTemp = Double(telemetry.engineTemperature)
                
                // Tyre temperatures
                if telemetry.tyresSurfaceTemperature.count == 4 {
                    self.tyreTempRL = Double(telemetry.tyresSurfaceTemperature[0])
                    self.tyreTempRR = Double(telemetry.tyresSurfaceTemperature[1])
                    self.tyreTempFL = Double(telemetry.tyresSurfaceTemperature[2])
                    self.tyreTempFR = Double(telemetry.tyresSurfaceTemperature[3])
                }
                
                self.lastUpdateTime = Date()
                let previousPackets = self.packetsReceived
                self.packetsReceived = self.telemetryListener.packetsReceived
                self.updateSessionInfo(from: packet.header)
                self.updateLastPacketTimestamp()
                
                // Log first packet received
                if previousPackets == 0 && self.packetsReceived > 0 {
                    print("🎮 First Car Telemetry packet received!")
                    print("   Speed: \(telemetry.speed) km/h, Gear: \(telemetry.gear), RPM: \(telemetry.engineRPM)")
                }
                
                print("✅ UI update complete - Speed: \(self.speed), Gear: \(self.gear)")
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
                self.currentLap = Int(lapData.currentLapNum)
                self.position = Int(lapData.carPosition)
                self.lapDistance = Double(lapData.lapDistance)
                
                // Format times
                self.lastLapTime = self.formatLapTime(lapData.lastLapTimeInMS)
                self.currentLapTime = self.formatLapTime(lapData.currentLapTimeInMS)
                self.sector1Time = self.formatSectorTime(lapData.sector1TimeInMS, minutes: lapData.sector1TimeMinutes)
                self.sector2Time = self.formatSectorTime(lapData.sector2TimeInMS, minutes: lapData.sector2TimeMinutes)
                
                // Delta to leader
                let deltaMS = Int(lapData.deltaToRaceLeaderInMS)
                let deltaSeconds = Double(deltaMS) / 1000.0
                self.deltaToLeader = String(format: "+%.3f", deltaSeconds)
                
                self.updateSessionInfo(from: packet.header)
                self.updateLastPacketTimestamp()
                
                // Log lap changes
                if previousLap > 0 && self.currentLap != previousLap {
                    print("🏁 Lap \(previousLap) completed! Last lap time: \(self.lastLapTime)")
                    print("   Now on lap \(self.currentLap), Position: P\(self.position)")
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
    
    // MARK: - Private Helpers
    
    private func startConnectionMonitoring() {
        connectionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let timeSinceUpdate = Date().timeIntervalSince(self.lastUpdateTime)
            let wasConnected = self.isConnected
            let nowConnected = timeSinceUpdate < 3.0 && self.telemetryListener.isListening
            
            DispatchQueue.main.async {
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
    
    private func updateSessionInfo(from header: PacketHeader) {
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
    
    deinit {
        connectionCheckTimer?.invalidate()
        stopListening()
    }
}

