import Foundation

// MARK: - Motion Packet (Packet ID 0)
/// Physics and motion data for all cars on track
struct CarMotionData {
    var worldPositionX: Float
    var worldPositionY: Float
    var worldPositionZ: Float
    var worldVelocityX: Float
    var worldVelocityY: Float
    var worldVelocityZ: Float
    var worldForwardDirX: Int16
    var worldForwardDirY: Int16
    var worldForwardDirZ: Int16
    var worldRightDirX: Int16
    var worldRightDirY: Int16
    var worldRightDirZ: Int16
    var gForceLateral: Float
    var gForceLongitudinal: Float
    var gForceVertical: Float
    var yaw: Float
    var pitch: Float
    var roll: Float

    static let size = 60 // 18 floats *4 + 6 int16 *2 = 72? Wait compute
    
    init(data: Data, offset: inout Int) {
        func read<T>(_ type: T.Type) -> T {
            let size = MemoryLayout<T>.size
            let value = data.subdata(in: offset..<offset+size).withUnsafeBytes { $0.load(as: T.self) }
            offset += size
            return value
        }
        
        worldPositionX = read(Float.self)
        worldPositionY = read(Float.self)
        worldPositionZ = read(Float.self)
        worldVelocityX = read(Float.self)
        worldVelocityY = read(Float.self)
        worldVelocityZ = read(Float.self)
        worldForwardDirX = read(Int16.self)
        worldForwardDirY = read(Int16.self)
        worldForwardDirZ = read(Int16.self)
        worldRightDirX = read(Int16.self)
        worldRightDirY = read(Int16.self)
        worldRightDirZ = read(Int16.self)
        gForceLateral = read(Float.self)
        gForceLongitudinal = read(Float.self)
        gForceVertical = read(Float.self)
        yaw = read(Float.self)
        pitch = read(Float.self)
        roll = read(Float.self)
    }
}

struct PacketMotionData {
    var header: PacketHeader
    var carMotionData: [CarMotionData] // 22 cars
    
    init?(data: Data) {
        guard data.count >= PacketHeader.size else { return nil }
        header = PacketHeader(data: data)
        var offset = PacketHeader.size
        var motions: [CarMotionData] = []
        for _ in 0..<22 {
            guard offset + CarMotionData.size <= data.count else { return nil }
            let motion = CarMotionData(data: data, offset: &offset)
            motions.append(motion)
        }
        carMotionData = motions
    }
}
