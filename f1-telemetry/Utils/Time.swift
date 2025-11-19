import Foundation

func formatTime(ms: Int32) -> String {
    guard ms > 0 else { return "--:--.---" }
    let totalSeconds = Double(ms) / 1000.0
    let minutes = Int(totalSeconds / 60)
    let seconds = totalSeconds.truncatingRemainder(dividingBy: 60)
    return String(format: "%d:%06.3f", minutes, seconds)
}

func formatDelta(ms: Int32) -> String {
    let seconds = Double(ms) / 1000.0
    return String(format: "%+.3f", seconds)
}