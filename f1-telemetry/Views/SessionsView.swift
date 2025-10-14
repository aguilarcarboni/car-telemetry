import SwiftUI
import SwiftData

struct SessionsView: View {
    @Query(sort: \RaceSession.createdAt, order: .reverse) private var sessions: [RaceSession]
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        NavigationStack {
            List {
                ForEach(sessions) { session in
                    NavigationLink(value: session) {
                        VStack(alignment: .leading) {
                            Text("Session \(session.sessionUID)")
                                .font(.headline)
                            Text(session.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteSessions)
            }
            .navigationDestination(for: RaceSession.self) { session in
                LapListView(session: session)
            }
            .navigationTitle("Sessions")
        }
        .toolbar { EditButton() }
    }
}

private struct LapListView: View {
    @Bindable var session: RaceSession
    var body: some View {
        List((session.lapSummaries ?? []).sorted { $0.lapNumber < $1.lapNumber }) { lap in
            NavigationLink(destination: LapView(lap: lap)) {
                HStack {
                    Text("Lap \(lap.lapNumber)")
                    Spacer()
                    Text(formatTime(ms: lap.lapTimeMS))
                        .monospacedDigit()
                }
            }
        }
        .navigationTitle("Session \(session.sessionUID)")
    }
    private func formatTime(ms: Int32) -> String {
        guard ms > 0 else { return "--:--.---" }
        let totalSeconds = Double(ms) / 1000.0
        let minutes = Int(totalSeconds / 60)
        let seconds = totalSeconds.truncatingRemainder(dividingBy: 60)
        return String(format: "%d:%06.3f", minutes, seconds)
    }
}

extension SessionsView {
    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            let session = sessions[index]
            modelContext.delete(session)
        }
    }
}

#Preview {
    SessionsView()
        .modelContainer(PersistenceController.shared.modelContainer)
}
