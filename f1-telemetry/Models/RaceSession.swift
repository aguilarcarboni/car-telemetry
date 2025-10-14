import SwiftData
import Foundation

@Model
final class RaceSession {
    var sessionUID: UInt64 = 0
    var sessionType: Int16 = 0
    var trackId: Int16 = 0
    var createdAt: Date = Date()
    @Relationship(inverse: \LapSummary.session) var lapSummaries: [LapSummary]? = []

    init(sessionUID: UInt64 = 0, sessionType: Int16 = 0, trackId: Int16 = 0) {
        self.sessionUID = sessionUID
        self.sessionType = sessionType
        self.trackId = trackId
    }
}