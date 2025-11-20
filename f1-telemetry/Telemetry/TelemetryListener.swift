//
//  TelemetryListener.swift
//  f1-tracker
//
//  UDP Listener for F1 24 Telemetry
//

import Foundation
import Network
import Combine

class TelemetryListener: ObservableObject {
    private var listener: NWListener?
    private let port: UInt16
    private let queue = DispatchQueue(label: "com.f1tracker.telemetry", qos: .userInitiated)
    
    @Published var isListening = false
    @Published var lastError: String?
    @Published var packetsReceived: Int = 0
    
    // Callbacks for different packet types
    var onTelemetryReceived: ((PacketCarTelemetryData) -> Void)?
    var onLapDataReceived: ((PacketLapData) -> Void)?
    var onCarStatusReceived: ((PacketCarStatusData) -> Void)?
    var onSessionReceived: ((PacketSessionData) -> Void)?
    var onMotionReceived: ((PacketMotionData) -> Void)?
    var onParticipantsReceived: ((PacketParticipantsData) -> Void)?
    var onDamageReceived: ((PacketCarDamageData) -> Void)?
    var onFinalClassificationReceived: ((PacketFinalClassificationData) -> Void)?
    
    init(port: UInt16 = 20777) {
        self.port = port
    }
    
    func startListening() {
        guard listener == nil else {
            print("⚠️ Already listening")
            return
        }
        
        do {
            let params = NWParameters.udp
            params.allowLocalEndpointReuse = true
            params.acceptLocalOnly = false
            
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
            
            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.isListening = true
                        self?.lastError = nil
                        print("✅ F1 Telemetry Listener ready on port \(self?.port ?? 0)")
                    case .failed(let error):
                        self?.isListening = false
                        self?.lastError = "Failed: \(error.localizedDescription)"
                        print("❌ Listener failed: \(error)")
                    case .cancelled:
                        self?.isListening = false
                        print("🛑 Listener cancelled")
                    default:
                        break
                    }
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                print("🆕 New connection handler triggered! Endpoint: \(connection.endpoint)")
                self?.handleConnection(connection)
            }
            
            print("▶️ Starting NWListener on queue...")
            listener?.start(queue: queue)
            print("✅ NWListener start() called")
            
        } catch {
            DispatchQueue.main.async {
                self.lastError = "Failed to create listener: \(error.localizedDescription)"
                print("❌ Failed to create listener: \(error)")
            }
        }
    }
    
    func stopListening() {
        listener?.cancel()
        listener = nil
        DispatchQueue.main.async {
            self.isListening = false
        }
    }
    
    private func handleConnection(_ connection: NWConnection) {
        print("🔗 New connection established from: \(String(describing: connection.endpoint))")
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("📡 Connection ready from \(String(describing: connection.endpoint))")
            case .failed(let error):
                print("❌ Connection failed: \(error)")
            case .waiting(let error):
                print("⏳ Connection waiting: \(error)")
            case .cancelled:
                print("🛑 Connection cancelled")
            default:
                break
            }
        }
        
        connection.start(queue: queue)
        receiveData(on: connection)
    }
    
    private func receiveData(on connection: NWConnection) {
        print("👂 Setting up receiveMessage handler on connection")
        connection.receiveMessage { [weak self] data, context, isComplete, error in
            guard let self = self else {
                print("❌ Self is nil in receiveMessage")
                return
            }
            
            if let error = error {
                print("❌ Receive error: \(error)")
                return
            }
            
            if let data = data, !data.isEmpty {
                print("📨 Received data packet: \(data.count) bytes")
                self.handlePacket(data)
                
                DispatchQueue.main.async {
                    self.packetsReceived += 1
                    
                    // Log every 100 packets to show activity
                    if self.packetsReceived % 100 == 0 {
                        print("📦 Received \(self.packetsReceived) packets so far...")
                    }
                }
            } else {
                print("⚠️ Received empty or nil data - isComplete: \(isComplete)")
            }
            
            // UDP datagrams are always "complete" individually, but we want to keep receiving
            // Always continue receiving for UDP connections
            self.receiveData(on: connection)
        }
    }
    
    private func handlePacket(_ data: Data) {
        // Parse the header first
        guard data.count >= PacketHeader.size else {
            print("⚠️ Packet too small: \(data.count) bytes")
            return
        }
        
        let header = PacketHeader(data: data)
        
        // Verify packet format
        guard header.packetFormat == 2024 else {
            print("⚠️ Unknown packet format: \(header.packetFormat) (expected 2024)")
            return
        }
        
        // Log first successful packet parsing
        if packetsReceived == 0 {
            print("✅ First valid F1 2024 packet received!")
            print("📋 Packet Header Info:")
            print("   Session UID: \(header.sessionUID)")
            print("   Session Time: \(header.sessionTime)s")
            print("   Frame: \(header.frameIdentifier)")
            print("   Overall Frame: \(header.overallFrameIdentifier)")
            print("   Player Car Index: \(header.playerCarIndex)")
        }
        
        // Route to appropriate parser based on packet ID
        guard let packetType = PacketType(rawValue: header.packetId) else {
            print("⚠️ Unknown packet type: \(header.packetId)")
            return
        }
        
        // Log packet type distribution every 50 packets
        if packetsReceived % 50 == 0 && packetsReceived > 0 {
            print("📊 Packet received: \(getPacketTypeName(packetType)) (ID: \(header.packetId))")
        }
        
        switch packetType {
        case .carTelemetry:
            print("🚗 Car Telemetry packet received (size: \(data.count) bytes)")
            if let packet = PacketCarTelemetryData(data: data) {
                print("✅ Car Telemetry packet parsed successfully")
                print("   Callback is nil? \(onTelemetryReceived == nil)")
                onTelemetryReceived?(packet)
                print("   Callback invoked")
            } else {
                print("❌ Failed to parse Car Telemetry packet - data size: \(data.count), expected minimum: \(PacketHeader.size + CarTelemetryData.size * 22 + 3)")
            }
            
        case .lapData:
            print("🏁 Lap Data packet received (size: \(data.count) bytes)")
            if let packet = PacketLapData(data: data) {
                print("✅ Lap Data packet parsed successfully")
                print("   Callback is nil? \(onLapDataReceived == nil)")
                onLapDataReceived?(packet)
                print("   Callback invoked")
            } else {
                print("❌ Failed to parse Lap Data packet - data size: \(data.count), expected minimum: \(PacketHeader.size + LapData.size * 22 + 2)")
            }
            
        case .carStatus:
            print("📊 Car Status packet received (size: \(data.count) bytes)")
            if let packet = PacketCarStatusData(data: data) {
                print("✅ Car Status packet parsed successfully")
                print("   Callback is nil? \(onCarStatusReceived == nil)")
                onCarStatusReceived?(packet)
                print("   Callback invoked")
            } else {
                print("❌ Failed to parse Car Status packet - data size: \(data.count), expected minimum: \(PacketHeader.size + CarStatusData.size * 22)")
            }
            
        case .session:
            if let packet = PacketSessionData(data: data) {
                onSessionReceived?(packet)
            }
        case .motion:
            if let packet = PacketMotionData(data: data) {
                onMotionReceived?(packet)
            }
        case .participants:
            if let packet = PacketParticipantsData(data: data) {
                onParticipantsReceived?(packet)
            }
        case .carDamage:
            if let packet = PacketCarDamageData(data: data) {
                onDamageReceived?(packet)
            }
        case .finalClassification:
            if let packet = PacketFinalClassificationData(data: data) {
                onFinalClassificationReceived?(packet)
            }
        default:
            // Log other packet types we're receiving but not processing
            if packetsReceived % 100 == 0 {
                print("📦 Received \(getPacketTypeName(packetType)) packet (not processed)")
            }
            break
        }
    }
    
    private func getPacketTypeName(_ type: PacketType) -> String {
        switch type {
        case .motion: return "Motion"
        case .session: return "Session"
        case .lapData: return "Lap Data"
        case .event: return "Event"
        case .participants: return "Participants"
        case .carSetups: return "Car Setups"
        case .carTelemetry: return "Car Telemetry"
        case .carStatus: return "Car Status"
        case .finalClassification: return "Final Classification"
        case .lobbyInfo: return "Lobby Info"
        case .carDamage: return "Car Damage"
        case .sessionHistory: return "Session History"
        case .tyreSets: return "Tyre Sets"
        case .motionEx: return "Motion Ex"
        case .timeTrial: return "Time Trial"
        }
    }
    
    deinit {
        stopListening()
    }
}

