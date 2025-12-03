// ACTelemetryClient.swift
// Assetto Corsa UDP listener and parser
//
// This class handles the connection lifecycle, handshake, subscribe, packet
// reception, and exposes callbacks mirroring the existing TelemetryListener
// pattern so that TelemetryViewModel can consume data from either source.

import Foundation
import Network

final class ACTelemetryClient {
    // MARK: - AC Operation IDs
    private enum ACOperation: Int32 {
        case handshake = 0
        case subscribeUpdate = 1
        case subscribeSpot = 2
        case dismiss = 3
    }

    // MARK: - Public Callback Types
    var onHandshake: ((ACHandshakeResponse) -> Void)?
    var onUpdate: ((RTCarInfo) -> Void)?
    var onLap: ((RTLap) -> Void)?
    var onError: ((Error) -> Void)?

    // MARK: - Properties
    private let host: NWEndpoint.Host
    private let port: NWEndpoint.Port = 9996
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.cartelemetry.ac", qos: .userInitiated)
    private enum ClientState { case idle, awaitingHandshake, subscribed }
    private var state: ClientState = .idle

    // MARK: - Lifecycle
    init(host: String) {
        self.host = NWEndpoint.Host(host)
    }

    func connect() {
        print("🌐 AC Client: initiating UDP connection to \(host):\(port)")
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        state = .awaitingHandshake
        let conn = NWConnection(host: host, port: port, using: params)
        self.connection = conn

        conn.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                print("✅ AC Client: connection ready")
                self.sendHandshake()
                self.receiveLoop()
            case .failed(let error):
                self.onError?(error)
                print("❌ AC Client: connection failed – \(error)")
            case .waiting(let error):
                print("⏳ AC Client: waiting – \(error)")
                self.onError?(error)
            default:
                break
            }
        }

        conn.start(queue: queue)
    }

    func disconnect() {
        send(operation: .dismiss)
        connection?.cancel()
        connection = nil
    }

    // MARK: - Private helpers
    private func sendHandshake() {
        print("📤 AC Client: sending handshake")
        send(operation: .handshake)
    }

    private func sendSubscribe() {
        send(operation: .subscribeUpdate)
    }

    private func send(operation: ACOperation) {
        var data = Data()
        data.append(Int32(1).leData) // identifier
        data.append(Int32(1).leData) // version
        data.append(Int32(operation.rawValue).leData)
        connection?.send(content: data, completion: .contentProcessed({ [weak self] error in
            if let error { self?.onError?(error) }
            else { print("📤 AC Client: operation \(operation) sent") }
        }))
    }

    private func receiveLoop() {
        connection?.receiveMessage { [weak self] content, _, _, error in
            guard let self else { return }
            if let error { self.onError?(error); print("❌ AC Client: receive error – \(error)"); return }
            guard let content, !content.isEmpty else { self.receiveLoop(); return }
            self.handle(content)
            self.receiveLoop()
        }
    }

    private func handle(_ data: Data) {
        if state == .awaitingHandshake, let resp = ACHandshakeResponse(from: data) {
            print("✅ AC Client: received handshake response from server")
            onHandshake?(resp)
            sendSubscribe()
            state = .subscribed
            return
        }
        if let update = RTCarInfo(from: data) {
            print("📥 AC Client: RTCarInfo update (speed=\(update.speedKmh) kmh, lap=\(update.lap))")
            onUpdate?(update)
            return
        }
        if let lap = RTLap(from: data) {
            print("🏁 AC Client: RTLap event lap=\(lap.lap), time=\(lap.lapTimeMS)ms")
            onLap?(lap)
            return
        }
        print("⚠️ AC Client: unknown packet size \(data.count)")
        // Unknown packet size, ignore.
    }
}
