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
                self?.handleConnection(connection)
            }
            
            listener?.start(queue: queue)
            
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
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("📡 Connection ready from \(String(describing: connection.endpoint))")
            case .failed(let error):
                print("❌ Connection failed: \(error)")
            default:
                break
            }
        }
        
        connection.start(queue: queue)
        receiveData(on: connection)
    }
    
    private func receiveData(on connection: NWConnection) {
        connection.receiveMessage { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Receive error: \(error)")
                return
            }
            
            if let data = data, !data.isEmpty {
                self.handlePacket(data)
                
                DispatchQueue.main.async {
                    self.packetsReceived += 1
                }
            }
            
            // Continue receiving
            if !isComplete {
                self.receiveData(on: connection)
            }
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
            print("⚠️ Unknown packet format: \(header.packetFormat)")
            return
        }
        
        // Route to appropriate parser based on packet ID
        guard let packetType = PacketType(rawValue: header.packetId) else {
            print("⚠️ Unknown packet type: \(header.packetId)")
            return
        }
        
        switch packetType {
        case .carTelemetry:
            if let packet = PacketCarTelemetryData(data: data) {
                onTelemetryReceived?(packet)
            }
            
        case .lapData:
            if let packet = PacketLapData(data: data) {
                onLapDataReceived?(packet)
            }
            
        case .carStatus:
            if let packet = PacketCarStatusData(data: data) {
                onCarStatusReceived?(packet)
            }
            
        default:
            // We can add more packet types as needed
            break
        }
    }
    
    deinit {
        stopListening()
    }
}

