import SwiftUI

struct LapView: View {
    let lap: LapSummary
    var body: some View {
        Form {
            Section(header: Text("Overview")) {
                HStack {
                    Text("Lap Number")
                    Spacer()
                    Text("\(lap.lapNumber)")
                }
                HStack {
                    Text("Lap Time")
                    Spacer()
                    Text(formatTime(ms: lap.lapTimeMS))
                        .monospacedDigit()
                        .foregroundColor(lap.isValid ? .primary : .red)
                }
                if !lap.isValid {
                    Text("Lap Invalid")
                        .foregroundColor(.red)
                }
            }
            Section(header: Text("Sectors")) {
                HStack {
                    Text("Sector 1")
                    Spacer()
                    Text(formatTime(ms: lap.sector1MS))
                        .monospacedDigit()
                }
                HStack {
                    Text("Sector 2")
                    Spacer()
                    Text(formatTime(ms: lap.sector2MS))
                        .monospacedDigit()
                }
                HStack {
                    Text("Sector 3")
                    Spacer()
                    Text(formatTime(ms: lap.sector3MS))
                        .monospacedDigit()
                }
            }
        }
        .navigationTitle("Lap \(lap.lapNumber)")
    }

    private func formatTime(ms: Int32) -> String {
        guard ms > 0 else { return "--:--.---" }
        let totalSeconds = Double(ms) / 1000.0
        let minutes = Int(totalSeconds / 60)
        let seconds = totalSeconds.truncatingRemainder(dividingBy: 60)
        return String(format: "%d:%06.3f", minutes, seconds)
    }
}

#Preview {
    // Create a sample LapSummary for preview
    let sample = LapSummary(lapNumber: 1, lapTimeMS: 92543, s1: 30123, s2: 30500, s3: 31920, valid: true)
    LapView(lap: sample)
}
