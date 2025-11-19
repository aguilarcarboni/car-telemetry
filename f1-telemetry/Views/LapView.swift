import SwiftUI
import Charts

struct LapView: View {
    let lap: LapSummary
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        GeometryReader { proxy in
            let layout = LapDetailLayout(size: proxy.size)
            let theme = themeManager.selectedTeam
            let sessionLaps = lap.session?.lapSummaries ?? []
            let driverLaps = sessionLaps.filter { $0.vehicleIndex == lap.vehicleIndex }
            let driverFastest = bestLap(in: driverLaps)
            let sessionFastest = bestLap(in: sessionLaps)
            let comparisonEntries = LapComparisonEntry.entries(
                current: lap,
                driverFastest: driverFastest,
                sessionFastest: sessionFastest
            )
            let telemetrySamples = telemetrySamples(for: lap)
            
            ZStack {
                LinearGradient(
                    colors: theme.backgroundGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: layout.cardSpacing) {
                        overviewCard(theme: theme)
                        comparisonMatrixCard(entries: comparisonEntries, theme: theme)
                        telemetrySection(
                            samples: telemetrySamples,
                            theme: theme,
                            layout: layout
                        )
                    }
                    .padding(.horizontal, layout.horizontalPadding)
                    .padding(.vertical, layout.verticalPadding)
                }
            }
        }
        .navigationTitle("Lap \(lap.lapNumber)")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private func overviewCard(theme: TeamTheme) -> some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("Lap Overview", systemImage: "flag.checkered")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lap \(lap.lapNumber)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Vehicle \(vehicleDisplayNumber)")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    validityBadge(theme: theme)
                }
                
                Divider().background(Color.white.opacity(0.08))
                
                HStack(spacing: 12) {
                    StatChip(
                        label: "Lap Time",
                        value: formatTime(ms: lap.lapTimeMS),
                        color: theme.speedColor
                    )
                    StatChip(
                        label: "Status",
                        value: lap.isValid ? "Valid" : "Invalid",
                        color: lap.isValid ? theme.throttleColor : theme.brakeColor
                    )
                    StatChip(
                        label: "Vehicle",
                        value: vehicleLabel,
                        color: theme.secondaryAccent
                    )
                }
                
                if !lap.isValid {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(theme.brakeColor)
                        Text("Telemetry flagged this lap as invalid and excluded it from fastest-lap comparisons.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(12)
                    .background(
                        theme.brakeColor.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func comparisonMatrixCard(entries: [LapComparisonEntry], theme: TeamTheme) -> some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("Lap & Sector Comparison", systemImage: "tablecells")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                
                if entries.isEmpty {
                    Text("Log another lap to unlock comparisons.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                } else {
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                        GridRow {
                            Text("")
                            ForEach(ComparisonColumn.allCases) { column in
                                Text(column.title)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        Divider().gridCellColumns(ComparisonColumn.allCases.count + 1)
                        
                        ForEach(entries) { entry in
                            GridRow(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.label)
                                        .font(.subheadline.weight(entry.isCurrent ? .bold : .semibold))
                                        .foregroundStyle(.white)
                                    Text(entry.detail)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                
                                ForEach(ComparisonColumn.allCases) { column in
                                    ComparisonValueCell(
                                        value: entry.time(for: column),
                                        delta: entry.delta(for: column),
                                        highlight: entry.isCurrent && column == .lap,
                                        theme: theme
                                    )
                                }
                            }
                            Divider().gridCellColumns(ComparisonColumn.allCases.count + 1)
                        }
                    }
                }
                
                Text("Δ values compare each lap and sector against Lap \(lap.lapNumber). Negative means faster.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
    
    @ViewBuilder
    private func telemetrySection(
        samples: [LapTelemetrySample],
        theme: TeamTheme,
        layout: LapDetailLayout
    ) -> some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("Lap Telemetry", systemImage: "waveform.path.ecg")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                
                if samples.isEmpty {
                    ChartPlaceholder(
                        message: "Telemetry trace will appear once per-lap packets are stored",
                        minHeight: 220
                    )
                } else {
                    let metrics = TelemetryMetric.allMetrics(theme: theme)
                    LazyVGrid(columns: layout.telemetryColumns, spacing: 18) {
                        ForEach(metrics) { metric in
                            telemetryChart(metric: metric, samples: samples)
                        }
                    }
                }
                
                Text("Hook these charts up to real lap traces by persisting telemetry packets per lap. Currently showing a synthesized profile based on lap time.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
    
    @ViewBuilder
    private func telemetryChart(metric: TelemetryMetric, samples: [LapTelemetrySample]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(metric.label, systemImage: metric.icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
            
            Chart {
                ForEach(samples) { sample in
                    LineMark(
                        x: .value("Lap %", sample.distance * 100),
                        y: .value(metric.label, metric.value(from: sample))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(metric.color)
                    .lineStyle(.init(lineWidth: 2.5))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                let tickValues = stride(from: 0, through: 100, by: 25).map(Double.init)
                AxisMarks(values: tickValues) { value in
                    AxisGridLine()
                    AxisValueLabel("\(Int(value.as(Double.self) ?? 0))%")
                }
            }
            .chartYScale(domain: metric.range)
            .frame(height: 180)
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Subviews
    
    private func validityBadge(theme: TeamTheme) -> some View {
        let color = lap.isValid ? theme.throttleColor : theme.brakeColor
        let icon = lap.isValid ? "checkmark.circle.fill" : "xmark.octagon.fill"
        return Label(lap.isValid ? "Valid Lap" : "Invalid Lap", systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
    
    // MARK: - Helpers
    
    private var vehicleDisplayNumber: Int {
        Int(lap.vehicleIndex) + 1
    }
    
    private var vehicleLabel: String {
        "#\(vehicleDisplayNumber)"
    }
    
    private func bestLap(in laps: [LapSummary]) -> LapSummary? {
        laps
            .filter { $0.lapTimeMS > 0 }
            .min(by: { $0.lapTimeMS < $1.lapTimeMS })
    }
    
    private func telemetrySamples(for lap: LapSummary) -> [LapTelemetrySample] {
        LapTelemetrySample.placeholders(for: lap)
    }
}

private struct LapComparisonEntry: Identifiable {
    let id = UUID()
    let label: String
    let detail: String
    let isCurrent: Bool
    let lapTime: Int32
    let lapDelta: Int32
    let sectorTimes: [Int32]
    let sectorDeltas: [Int32]
    
    static func entries(
        current: LapSummary,
        driverFastest: LapSummary?,
        sessionFastest: LapSummary?
    ) -> [LapComparisonEntry] {
        var entries: [LapComparisonEntry] = []
        var usedIds: Set<UUID> = []
        
        entries.append(
            LapComparisonEntry(summary: current, reference: current, label: "This Lap", isCurrent: true)
        )
        usedIds.insert(current.id)
        
        if let driverFastest, driverFastest.lapTimeMS > 0, !usedIds.contains(driverFastest.id) {
            entries.append(
                LapComparisonEntry(summary: driverFastest, reference: current, label: "Your Fastest", isCurrent: false)
            )
            usedIds.insert(driverFastest.id)
        }
        
        if let sessionFastest, sessionFastest.lapTimeMS > 0, !usedIds.contains(sessionFastest.id) {
            entries.append(
                LapComparisonEntry(summary: sessionFastest, reference: current, label: "Session Fastest", isCurrent: false)
            )
        }
        
        return entries
    }
    
    private init(summary: LapSummary, reference: LapSummary, label: String, isCurrent: Bool) {
        self.label = label
        self.detail = "Lap \(summary.lapNumber) • Car #\(Int(summary.vehicleIndex) + 1) • \(summary.isValid ? "Valid" : "Invalid")"
        self.isCurrent = isCurrent
        self.lapTime = summary.lapTimeMS
        self.lapDelta = summary.lapTimeMS - reference.lapTimeMS
        self.sectorTimes = [
            summary.sector1MS,
            summary.sector2MS,
            summary.sector3MS
        ]
        self.sectorDeltas = [
            summary.sector1MS - reference.sector1MS,
            summary.sector2MS - reference.sector2MS,
            summary.sector3MS - reference.sector3MS
        ]
    }
    
    func time(for column: ComparisonColumn) -> Int32 {
        switch column {
        case .lap:
            return lapTime
        case .sector1:
            return sectorTimes[0]
        case .sector2:
            return sectorTimes[1]
        case .sector3:
            return sectorTimes[2]
        }
    }
    
    func delta(for column: ComparisonColumn) -> Int32 {
        switch column {
        case .lap:
            return lapDelta
        case .sector1:
            return sectorDeltas[0]
        case .sector2:
            return sectorDeltas[1]
        case .sector3:
            return sectorDeltas[2]
        }
    }
}

private enum ComparisonColumn: Int, CaseIterable, Identifiable {
    case lap
    case sector1
    case sector2
    case sector3
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .lap: return "Lap"
        case .sector1: return "Sector 1"
        case .sector2: return "Sector 2"
        case .sector3: return "Sector 3"
        }
    }
}

private struct ComparisonValueCell: View {
    let value: Int32
    let delta: Int32
    let highlight: Bool
    let theme: TeamTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formatTime(ms: value))
                .font(.system(.body, design: .rounded).monospacedDigit())
                .foregroundStyle(highlight ? theme.speedColor : .white)
            DeltaBadge(
                text: formatDelta(ms: delta),
                color: deltaColor
            )
        }
    }
    
    private var deltaColor: Color {
        switch delta {
        case let value where value < 0:
            return theme.throttleColor
        case let value where value > 0:
            return theme.brakeColor
        default:
            return .white.opacity(0.8)
        }
    }
}

private struct LapTelemetrySample: Identifiable {
    let id = UUID()
    let distance: Double
    let speed: Double
    let throttle: Double
    let brake: Double
    let gear: Double
    
    static func placeholders(for lap: LapSummary, resolution: Int = 64) -> [LapTelemetrySample] {
        guard resolution > 1 else { return [] }
        return (0..<resolution).map { index in
            let progress = Double(index) / Double(resolution - 1)
            let accel = sin(progress * .pi)
            let corner = sin(progress * .pi * 1.4 + .pi / 4)
            let speed = max(80, 90 + accel * 190 - abs(corner) * 20)
            let throttle = min(100, max(0, accel * 95 + cos(progress * .pi * 2) * 8))
            let brake = min(100, max(0, (1 - accel * 0.7) * abs(corner) * 90))
            let gear = max(1, min(8, round(progress * 8)))
            return LapTelemetrySample(
                distance: progress,
                speed: speed,
                throttle: throttle,
                brake: brake,
                gear: gear
            )
        }
    }
}

private struct TelemetryMetric: Identifiable {
    let id: String
    let label: String
    let icon: String
    let color: Color
    let range: ClosedRange<Double>
    let valueProvider: (LapTelemetrySample) -> Double
    
    func value(from sample: LapTelemetrySample) -> Double {
        valueProvider(sample)
    }
    
    static func allMetrics(theme: TeamTheme) -> [TelemetryMetric] {
        [
            TelemetryMetric(
                id: "speed",
                label: "Speed (km/h)",
                icon: "speedometer",
                color: theme.speedColor,
                range: 0...360,
                valueProvider: { $0.speed }
            ),
            TelemetryMetric(
                id: "throttle",
                label: "Throttle %",
                icon: "bolt.fill",
                color: theme.throttleColor,
                range: 0...100,
                valueProvider: { $0.throttle }
            ),
            TelemetryMetric(
                id: "brake",
                label: "Brake %",
                icon: "stop.fill",
                color: theme.brakeColor,
                range: 0...100,
                valueProvider: { $0.brake }
            ),
            TelemetryMetric(
                id: "gear",
                label: "Gear",
                icon: "gearshape.fill",
                color: theme.secondaryAccent,
                range: 0...9,
                valueProvider: { $0.gear }
            )
        ]
    }
}

private struct DeltaBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.18), in: Capsule())
    }
}

private struct LapDetailLayout {
    let size: CGSize
    let cardSpacing: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let usesWideLayout: Bool
    
    init(size: CGSize) {
        self.size = size
        self.cardSpacing = max(20, size.height * 0.03)
        self.horizontalPadding = max(20, size.width * 0.08)
        self.verticalPadding = max(24, size.height * 0.05)
        self.usesWideLayout = size.width >= 720
    }
    
    var telemetryColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 16),
            count: usesWideLayout ? 2 : 1
        )
    }
}

#Preview {
    let sample = LapSummary(
        lapNumber: 1,
        lapTimeMS: 92543,
        s1: 30123,
        s2: 30500,
        s3: 31920,
        valid: true
    )
    
    NavigationStack {
        LapView(lap: sample)
    }
    .environmentObject(ThemeManager())
}
