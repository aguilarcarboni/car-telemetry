import SwiftUI
import SwiftData

struct SessionView: View {
    @Bindable var session: RaceSession
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        GeometryReader { proxy in
            let layout = SessionsLayout(size: proxy.size)
            let laps = (session.lapSummaries ?? []).sorted { $0.lapNumber < $1.lapNumber }
            let theme = themeManager.selectedTeam
            let detailColumns = columns(for: proxy.size.width, minimum: 320)
            let lapColumns = columns(for: proxy.size.width, minimum: proxy.size.width > 520 ? 220 : 160)
            
            ZStack {
                LinearGradient(
                    colors: theme.backgroundGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                        overviewSection(laps: laps, theme: theme)
                        
                        LazyVGrid(columns: detailColumns, spacing: layout.cardSpacing) {
                            conditionsCard(theme: theme)
                        }
                        
                        finalClassificationCard(theme: theme)
                        
                        lapsSection(
                            laps: laps,
                            theme: theme,
                            columns: lapColumns
                        )
                    }
                    .padding(.vertical, layout.verticalPadding)
                    .padding(.horizontal, layout.horizontalPadding)
                }
            }
        }
        .navigationTitle(trackName(for: session.trackId))
    }
    
    @ViewBuilder
    private func overviewSection(laps: [LapSummary], theme: TeamTheme) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Session Overview",
                subtitle: "High-level snapshot of \(trackName(for: session.trackId))"
            )
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    MetricPill(
                        title: "Track",
                        value: trackName(for: session.trackId),
                        accent: theme.accent
                    )
                    MetricPill(
                        title: "Laps Logged",
                        value: "\(laps.count)",
                        accent: theme.speedColor
                    )
                    MetricPill(
                        title: "Best Lap",
                        value: bestLapLabel(from: laps),
                        accent: theme.gLongColor
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func conditionsCard(theme: TeamTheme) -> some View {
        TelemetryCard {
            SectionHeader(
                title: "Conditions",
                subtitle: "Weather + surface, coming from upcoming packets"
            )
            
            Divider().background(Color.white.opacity(0.08))
            
            VStack(spacing: 12) {
                ConditionRow(label: "Weather", value: "Awaiting data", icon: "cloud.sun.rain")
                ConditionRow(label: "Air Temp", value: "-- °C", icon: "thermometer.medium")
                ConditionRow(label: "Track Temp", value: "-- °C", icon: "thermometer.sun")
                ConditionRow(label: "Surface", value: "Pending", icon: "steeringwheel")
            }
            
            Text("We'll populate this section as soon as session packets start persisting conditions.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 8)
        }
    }
    
    @ViewBuilder
    private func finalClassificationCard(theme: TeamTheme) -> some View {
        let rows = ClassificationRow.placeholderRows
        
        TelemetryCard {
            SectionHeader(
                title: "Final Classification",
                subtitle: "Finishing order and points once we capture classification packets"
            )
            
            Divider().background(Color.white.opacity(0.08))
            
            VStack(spacing: 10) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    ClassificationRowView(row: row)
                    if index < rows.count - 1 {
                        Divider().background(Color.white.opacity(0.06))
                    }
                }
            }
            
            Text("Hook up the classification packet storage to replace this preview with real finishing places.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 12)
        }
    }
    
    @ViewBuilder
    private func lapsSection(laps: [LapSummary], theme: TeamTheme, columns: [GridItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "All Laps",
                subtitle: laps.isEmpty ? "No laps recorded for this session yet" : "Tap a lap for sector-by-sector telemetry"
            )
            
            if laps.isEmpty {
                ChartPlaceholder(
                    message: "Drive a lap to start building this section",
                    minHeight: 200
                )
                .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(laps) { lap in
                        NavigationLink(destination: LapView(lap: lap)) {
                            LapTile(lap: lap, theme: theme)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private func bestLapLabel(from laps: [LapSummary]) -> String {
        guard let best = laps
            .filter({ $0.isValid })
            .min(by: { $0.lapTimeMS < $1.lapTimeMS }) ?? laps.min(by: { $0.lapTimeMS < $1.lapTimeMS }) else {
            return "--:--.---"
        }
        return formatTime(ms: best.lapTimeMS)
    }
    
    private func columns(for width: CGFloat, minimum: CGFloat) -> [GridItem] {
        let target = max(minimum, 140)
        let available = max(width - 40, 180)
        let finalMinimum = min(available, target)
        return [
            GridItem(.adaptive(minimum: finalMinimum), spacing: 18, alignment: .top)
        ]
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
        }
    }
}

private struct ConditionRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
    }
}

private struct ClassificationRow: Identifiable {
    let id = UUID()
    let position: Int
    let label: String
    let detail: String
    let gap: String
    
    static let placeholderRows: [ClassificationRow] = [
        ClassificationRow(position: 1, label: "Waiting for finish order", detail: "Captured once we log classification packets", gap: "--"),
        ClassificationRow(position: 2, label: "—", detail: "—", gap: "--"),
        ClassificationRow(position: 3, label: "—", detail: "—", gap: "--")
    ]
}

private struct ClassificationRowView: View {
    let row: ClassificationRow
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(row.position)")
                .font(.system(.title3, design: .rounded).monospacedDigit())
                .foregroundStyle(.white.opacity(0.65))
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(row.detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Text(row.gap)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

private struct LapTile: View {
    let lap: LapSummary
    let theme: TeamTheme
    
    var body: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Lap \(lap.lapNumber)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    ValidityBadge(isValid: lap.isValid)
                }
                
                Text(formatTime(ms: lap.lapTimeMS))
                    .font(.system(.title3, design: .rounded).monospacedDigit())
                    .foregroundStyle(theme.speedColor)
                
                HStack(spacing: 8) {
                    CompactStatChip(label: "S1", value: formatTime(ms: lap.sector1MS), color: theme.accent)
                    CompactStatChip(label: "S2", value: formatTime(ms: lap.sector2MS), color: theme.secondaryAccent)
                    CompactStatChip(label: "S3", value: formatTime(ms: lap.sector3MS), color: theme.gLongColor)
                }
            }
        }
    }
}

private struct CompactStatChip: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(color.opacity(0.7))
            Text(value)
                .font(.system(.footnote, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct ValidityBadge: View {
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.caption.weight(.bold))
            Text(isValid ? "Valid" : "Invalid")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(isValid ? Color.green.opacity(0.9) : Color.orange.opacity(0.9))
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            (isValid ? Color.green.opacity(0.15) : Color.orange.opacity(0.15)),
            in: Capsule()
        )
    }
}
