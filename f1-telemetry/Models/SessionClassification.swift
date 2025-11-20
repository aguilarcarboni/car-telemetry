import Foundation
import SwiftData

@Model
final class SessionClassification {
    var id: UUID = UUID()
    @Relationship var session: RaceSession?
    @Relationship var stints: [SessionStint]? = []
    
    var vehicleIndex: Int16 = 0
    var driverName: String = ""
    var teamId: UInt8 = 0
    var position: UInt8 = 0
    var numLaps: UInt8 = 0
    var gridPosition: UInt8 = 0
    var points: UInt8 = 0
    var numPitStops: UInt8 = 0
    var resultStatus: UInt8 = 0
    var bestLapTimeMS: UInt32 = 0
    var totalRaceTimeSeconds: Double = 0
    var penaltiesTime: UInt8 = 0
    var numPenalties: UInt8 = 0
    
    init(
        session: RaceSession? = nil,
        vehicleIndex: Int16,
        driverName: String,
        teamId: UInt8,
        position: UInt8,
        numLaps: UInt8,
        gridPosition: UInt8,
        points: UInt8,
        numPitStops: UInt8,
        resultStatus: UInt8,
        bestLapTimeMS: UInt32,
        totalRaceTimeSeconds: Double,
        penaltiesTime: UInt8,
        numPenalties: UInt8
    ) {
        self.session = session
        self.vehicleIndex = vehicleIndex
        self.driverName = driverName
        self.teamId = teamId
        self.position = position
        self.numLaps = numLaps
        self.gridPosition = gridPosition
        self.points = points
        self.numPitStops = numPitStops
        self.resultStatus = resultStatus
        self.bestLapTimeMS = bestLapTimeMS
        self.totalRaceTimeSeconds = totalRaceTimeSeconds
        self.penaltiesTime = penaltiesTime
        self.numPenalties = numPenalties
    }
}

