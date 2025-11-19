import SwiftUI
import SwiftData

struct SessionsView: View {
    @Query(sort: \RaceSession.createdAt, order: .reverse) private var sessions: [RaceSession]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let layout = SessionsLayout(size: proxy.size)
                let theme = themeManager.selectedTeam
                
                ZStack {
                    LinearGradient(
                        colors: theme.backgroundGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                            summaryRow
                            
                            if sessions.isEmpty {
                                ChartPlaceholder(
                                    message: "No sessions stored yet",
                                    minHeight: 260
                                )
                            } else {
                                LazyVStack(spacing: layout.cardSpacing) {
                                    ForEach(sessions) { session in
                                        NavigationLink(value: session) {
                                            SessionCard(session: session, theme: theme)
                                        }
                                        .buttonStyle(.plain)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                delete(session)
                                            } label: {
                                                Label("Delete Session", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, layout.verticalPadding)
                        .padding(.horizontal, layout.horizontalPadding)
                    }
                }
                .navigationDestination(for: RaceSession.self) { session in
                    SessionView(session: session)
                }
            }
        }
    }
    
    private var summaryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                MetricPill(
                    title: "Sessions",
                    value: "\(sessions.count)",
                    accent: themeManager.selectedTeam.accent
                )
                
                MetricPill(
                    title: "Total Laps",
                    value: "\(totalLapsLogged)",
                    accent: themeManager.selectedTeam.speedColor
                )
                
                MetricPill(
                    title: "Last Track",
                    value: latestTrackLabel,
                    accent: themeManager.selectedTeam.secondaryAccent
                )
            }
        }
    }
    
    private var totalLapsLogged: Int {
        sessions.reduce(0) { result, session in
            result + (session.lapSummaries?.count ?? 0)
        }
    }
    
    private var latestTrackLabel: String {
        guard let session = sessions.first else { return "--" }
        return trackName(for: session.trackId)
    }
    
    private func delete(_ session: RaceSession) {
        modelContext.delete(session)
    }
}

private struct SessionCard: View {
    let session: RaceSession
    let theme: TeamTheme
    
    var body: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.createdAt, format: .dateTime.day().month().year().hour().minute())
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                
                Divider().background(Color.white.opacity(0.08))
                
                HStack(spacing: 12) {
                    StatChip(
                        label: "Track",
                        value: trackName(for: session.trackId),
                        color: theme.accent
                    )
                    StatChip(
                        label: "Laps",
                        value: "\(session.lapSummaries?.count ?? 0)",
                        color: theme.speedColor
                    )
                }
            }
        }
    }
}

// MARK: - Layout

struct SessionsLayout {
    let size: CGSize
    let sectionSpacing: CGFloat
    let cardSpacing: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    
    init(size: CGSize) {
        self.size = size
        self.sectionSpacing = max(20, size.height * 0.035)
        self.cardSpacing = 18
        self.horizontalPadding = max(20, size.width * 0.05)
        self.verticalPadding = max(24, size.height * 0.04)
    }
}

#Preview {
    SessionsView()
        .modelContainer(PersistenceController.shared.modelContainer)
        .environmentObject(ThemeManager())
}
