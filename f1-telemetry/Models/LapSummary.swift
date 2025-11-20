import SwiftData
import Foundation

@Model
final class LapSummary {
    var id: UUID = UUID()
    @Relationship var session: RaceSession?
    @Relationship var telemetryTrace: LapTelemetryTrace?
    var vehicleIndex: Int16 = 0
    var lapNumber: Int16 = 0
    var lapTimeMS: Int32 = 0
    var sector1MS: Int32 = 0
    var sector2MS: Int32 = 0
    var sector3MS: Int32 = 0
    var isValid: Bool = false

    init(session: RaceSession? = nil, telemetryTrace: LapTelemetryTrace? = nil, vehicleIndex:Int16 = 0, lapNumber:Int16 = 0, lapTimeMS:Int32 = 0, s1:Int32 = 0, s2:Int32 = 0, s3:Int32 = 0, valid:Bool = false) {
        self.session = session
        self.telemetryTrace = telemetryTrace
        self.vehicleIndex = vehicleIndex
        self.lapNumber = lapNumber
        self.lapTimeMS = lapTimeMS
        self.sector1MS = s1
        self.sector2MS = s2
        self.sector3MS = s3
        self.isValid = valid
    }
}
