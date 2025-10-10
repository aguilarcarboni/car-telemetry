//
//  TelemetryViewModel.swift
//  f1-tracker
//
//  ViewModel for managing F1 telemetry state
//

import Foundation
import SwiftUI
import Combine

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
    
    private let telemetryListener: TelemetryListener
    private var connectionCheckTimer: Timer?
    
    init(port: UInt16 = 20777) {
        telemetryListener = TelemetryListener(port: port)
        setupCallbacks()
        startConnectionMonitoring()
    }
    
    // MARK: - Setup
    
    private func setupCallbacks() {
        // Handle Car Telemetry packets
        telemetryListener.onTelemetryReceived = { [weak self] packet in
            guard let self = self else { return }
            let playerIndex = Int(packet.header.playerCarIndex)
            guard playerIndex < packet.carTelemetryData.count else { return }
            
            let telemetry = packet.carTelemetryData[playerIndex]
            
            DispatchQueue.main.async {
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
                self.packetsReceived = self.telemetryListener.packetsReceived
            }
        }
        
        // Handle Lap Data packets
        telemetryListener.onLapDataReceived = { [weak self] packet in
            guard let self = self else { return }
            let playerIndex = Int(packet.header.playerCarIndex)
            guard playerIndex < packet.lapData.count else { return }
            
            let lapData = packet.lapData[playerIndex]
            
            DispatchQueue.main.async {
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
            }
        }
        
        // Handle Car Status packets
        telemetryListener.onCarStatusReceived = { [weak self] packet in
            guard let self = self else { return }
            let playerIndex = Int(packet.header.playerCarIndex)
            guard playerIndex < packet.carStatusData.count else { return }
            
            let status = packet.carStatusData[playerIndex]
            
            DispatchQueue.main.async {
                self.fuelInTank = Double(status.fuelInTank)
                self.fuelCapacity = Double(status.fuelCapacity)
                self.fuelRemainingLaps = Double(status.fuelRemainingLaps)
                self.maxRPM = Double(status.maxRPM)
                self.tyreAge = Int(status.tyresAgeLaps)
                self.tyreCompound = self.getTyreCompoundName(status.visualTyreCompound)
                self.drsAvailable = status.drsAllowed == 1
                self.ersStoreEnergy = Double(status.ersStoreEnergy)
                self.ersDeployMode = self.getERSModeName(status.ersDeployMode)
            }
        }
    }
    
    // MARK: - Public Methods
    
    func startListening() {
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
            DispatchQueue.main.async {
                self.isConnected = timeSinceUpdate < 3.0 && self.telemetryListener.isListening
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
    
    deinit {
        connectionCheckTimer?.invalidate()
        stopListening()
    }
}

