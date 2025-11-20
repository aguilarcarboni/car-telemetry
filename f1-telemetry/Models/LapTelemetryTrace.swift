import SwiftData
import Foundation

@Model
final class LapTelemetryTrace {
    var id: UUID = UUID()
    @Relationship(inverse: \LapSummary.telemetryTrace) var lap: LapSummary?
    var samplesData: Data?
    var sampleCount: Int = 0
    
    init(lap: LapSummary? = nil, samples: [LapTelemetrySample] = []) {
        self.lap = lap
        updateSamples(samples)
    }
    
    func updateSamples(_ samples: [LapTelemetrySample]) {
        guard !samples.isEmpty else {
            samplesData = nil
            sampleCount = 0
            return
        }
        
        do {
            samplesData = try JSONEncoder().encode(samples)
            sampleCount = samples.count
        } catch {
            print("⚠️ Failed to encode lap telemetry samples: \(error)")
        }
    }
    
    func decodedSamples() -> [LapTelemetrySample] {
        guard let samplesData else { return [] }
        do {
            return try JSONDecoder().decode([LapTelemetrySample].self, from: samplesData)
        } catch {
            print("⚠️ Failed to decode lap telemetry samples: \(error)")
            return []
        }
    }
}

