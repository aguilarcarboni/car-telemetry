import Foundation
import SwiftData

@Model
final class SessionStint {
    var id: UUID = UUID()
    @Relationship(inverse: \SessionClassification.stints) var classification: SessionClassification?
    
    var stintIndex: UInt8 = 0
    var actualCompound: UInt8 = 0
    var visualCompound: UInt8 = 0
    var endLap: UInt8 = 0
    
    init(
        classification: SessionClassification? = nil,
        stintIndex: UInt8,
        actualCompound: UInt8,
        visualCompound: UInt8,
        endLap: UInt8
    ) {
        self.classification = classification
        self.stintIndex = stintIndex
        self.actualCompound = actualCompound
        self.visualCompound = visualCompound
        self.endLap = endLap
    }
}

