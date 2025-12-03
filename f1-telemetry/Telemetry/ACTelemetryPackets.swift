// ACTelemetryPackets.swift
// Assetto Corsa UDP packet structures and little-endian parsing helpers
//
// This file defines the handshake response as well as the RTCarInfo and RTLap
// data packets sent by Assetto Corsa when using the Remote UDP API.
// Only the subset of fields required for UI updates and persistence are parsed
// initially; the rest can be filled in later following the official documentation.

import Foundation

// MARK: - Helpers
extension FixedWidthInteger {
    var leData: Data {
        var v = self.littleEndian
        return withUnsafeBytes(of: &v) { Data($0) }
    }
}

fileprivate extension Data {
    mutating func read<T: FixedWidthInteger>(_ type: T.Type) -> T {
        let size = MemoryLayout<T>.size
        let value = self.prefix(size).withUnsafeBytes { $0.load(as: T.self) }
        self.removeFirst(size)
        return T(littleEndian: value)
    }

    mutating func readFloat() -> Float {
        let size = MemoryLayout<Float>.size
        let value = self.prefix(size).withUnsafeBytes { $0.load(as: Float.self) }
        self.removeFirst(size)
        return value
    }

    mutating func readCString(maxLength: Int) -> String {
        let slice = self.prefix(maxLength)
        self.removeFirst(maxLength)
        if let str = String(bytes: slice, encoding: .utf8) {
            return str.split(separator: "\0").first.map(String.init) ?? str
        }
        return ""
    }
}

// MARK: - AC Handshake Response
struct ACHandshakeResponse {
    let carName: String
    let driverName: String
    let identifier: Int32
    let version: Int32
    let trackName: String
    let trackConfig: String

    init?(from data: Data) {
        guard data.count >= 50*4 + 8 else { return nil }
        var copy = data
        self.carName = copy.readCString(maxLength: 50)
        self.driverName = copy.readCString(maxLength: 50)
        self.identifier = copy.read(Int32.self)
        self.version = copy.read(Int32.self)
        self.trackName = copy.readCString(maxLength: 50)
        self.trackConfig = copy.readCString(maxLength: 50)
    }
}

// MARK: - RTCarInfo (update) – subset only
struct RTCarInfo {
    // Minimal fields we care about
    let speedKmh: Float
    let gas: Float
    let brake: Float
    let engineRPM: Float
    let steer: Float
    let gear: Int32
    let gVert: Float
    let gHor: Float
    let gFront: Float
    let lapTimeMS: Int32
    let lap: Int32
    let frontSlip: Float
    let rearSlip: Float

    init?(from data: Data) {
        guard data.count >= 304 else { return nil } // documented size ~304 bytes
        var offset = 0
        func readInt32() -> Int32 {
            let raw = data.subdata(in: offset..<offset+4).withUnsafeBytes { $0.load(as: Int32.self) }
            offset += 4
            return Int32(littleEndian: raw)
        }
        func readFloat() -> Float {
            defer { offset += 4 }
            return data.subdata(in: offset..<(offset+4)).withUnsafeBytes{ $0.load(as: Float.self) }
        }
        func skip(_ bytes: Int) { offset += bytes }

        // 1) identifier char 'a' + 3 bytes pad to align next int32
        skip(1)  // 'a'
        skip(3)  // padding

        // 2) size int32 (we ignore content)
        let _ = readInt32()

        // 3) Speeds
        speedKmh = readFloat(); skip(8) // mph + ms

        // 4) six bools
        skip(6)
        // align to 4-byte boundary (2 pad bytes)
        skip(2)

        // 5) accelerations
        gVert = readFloat(); gHor = readFloat(); gFront = readFloat()

        // 6) lap times and counts
        lapTimeMS = readInt32(); skip(8); lap = readInt32()

        // 7) controls
        gas = readFloat(); brake = readFloat(); skip(4) // clutch
        engineRPM = readFloat(); steer = readFloat(); gear = readInt32();
        skip(4) // cgHeight

        // wheelAngularSpeed[4] slipAngle[4] slipAngleContactPatch[4] -> skip 16*3 = 48 bytes
        skip(48)
        // slipRatio[4] -> skip 16
        skip(16)
        // tyreSlip[4]
        var slip: [Float] = []
        for _ in 0..<4 { slip.append(readFloat()) }
        // basic mapping: 0 RL,1 RR,2 FL,3 FR per AC docs
        rearSlip = (slip[0] + slip[1]) / 2
        frontSlip = (slip[2] + slip[3]) / 2

        // Note: skipping the rest of the packet

        // More sanity
        if !speedKmh.isFinite || speedKmh < -20 || speedKmh > 400 { return nil }
        if gear < -1 || gear > 8 { return nil }
    }
}

// MARK: - RTLap (spot) – minimal subset
struct RTLap {
    let lapTimeMS: Int32
    let carIdentifier: Int32
    let lap: Int32

    init?(from data: Data) {
        guard data.count >= 12 else { return nil }
        var copy = data
        lapTimeMS = copy.read(Int32.self)
        carIdentifier = copy.read(Int32.self)
        lap = copy.read(Int32.self)
    }
}
