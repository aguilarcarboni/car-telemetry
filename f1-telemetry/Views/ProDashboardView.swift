//
//  ProDashboardView.swift
//  f1-telemetry
//
//  Created by Cursor on 11/17/2025.
//

import SwiftUI
import Charts
import Combine

struct ProDashboardView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    
    private let chartTimeWindow: TimeInterval = 20
    
    var body: some View {
        GeometryReader { proxy in
            let layout = DashboardLayoutMetrics(size: proxy.size)
            
            ZStack {
                backgroundLayer
                
                VStack(alignment: .leading, spacing: layout.cardSpacing) {
                    if isSafetyCarActive {
                        safetyCarBanner
                    }
                    if layout.usesWideLayout {
                        HStack(alignment: .top, spacing: layout.cardSpacing) {
                            performanceSection(layout: layout)
                                .frame(maxWidth: .infinity)
                            
                            VStack(spacing: layout.cardSpacing) {
                                statsSection
                                damageSection
                            }
                            .frame(maxWidth: .infinity, alignment: .top)
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                    } else {
                        VStack(spacing: layout.cardSpacing) {
                            performanceSection(layout: layout)
                            statsSection
                            damageSection
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.vertical, layout.verticalPadding)
                .padding(.horizontal, layout.horizontalPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }
    
    // MARK: - Sections
    
    private var selectedTeam: TeamTheme {
        themeManager.selectedTeam
    }

    private var isSafetyCarActive: Bool {
        viewModel.safetyCarStatus != 0
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if isSafetyCarActive {
            Color.yellow.opacity(0.9)
                .ignoresSafeArea()
        } else {
            LinearGradient(
                colors: selectedTeam.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
    
    private var safetyCarBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.title2.bold())
            VStack(alignment: .leading, spacing: 4) {
                Text("Safety Car Deployed")
                    .font(.headline)
                Text(safetyCarLabel(for: viewModel.safetyCarStatus))
                    .font(.subheadline)
                    .opacity(0.8)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.85))
        )
        .foregroundStyle(Color.black)
    }
    
    private func performanceSection(layout: DashboardLayoutMetrics) -> some View {
        TelemetryCard {
            VStack(spacing: 16) {
                speedChartBlock(height: layout.primaryChartHeight)
                
                Divider().background(Color.white.opacity(0.08))
                
                inputChart(
                    for: viewModel.throttleHistory,
                    label: "Throttle",
                    icon: "bolt.fill",
                    color: selectedTeam.throttleColor,
                    height: layout.inputChartHeight
                )

                Divider().background(Color.white.opacity(0.08))
                
                inputChart(
                    for: viewModel.brakeHistory,
                    label: "Brake",
                    icon: "hand.raised.fill",
                    color: selectedTeam.brakeColor,
                    height: layout.inputChartHeight
                )
                
            }
        }
    }
    
    private var statsSection: some View {
        VStack(spacing: 10) {
            TelemetryCard {
                VStack(spacing: 18) {
                    HStack(spacing: 5) {
                        
                        handlingBalanceCard
                        
                        Divider().background(Color.white.opacity(0.08))
                        
                        tractionCircleSection
                        
                    }
                    Divider().background(Color.white.opacity(0.08))
                    statChipRow
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var handlingBalanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.handlingBalance.displayName)
                .font(.headline)
                .foregroundStyle(handlingColor(for: viewModel.handlingBalance))

            handlingBalanceGraph
                .frame(height: 150)
        }
    }
    
    @ViewBuilder
    private var rpmGaugeView: some View {
        VStack(spacing: 12) {
            Gauge(value: currentRPMValue, in: 0...max(rpmGaugeMax, 1)) {
                EmptyView()
            } currentValueLabel: {
                Text("\(Int(viewModel.rpm))")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(selectedTeam.accent)
            }
            .gaugeStyle(.accessoryCircular)
            .controlSize(.extraLarge)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .tint(
                Gradient(colors: [
                    selectedTeam.accent,
                    .orange,
                    .red
                ])
            )
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 220)
    }
    
    @ViewBuilder
    private var tractionCircleSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Spacer()
                Text(tractionUtilizationDisplay)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(selectedTeam.throttleColor)
            }
            
            if gForceSamples.isEmpty {
                ChartPlaceholder(
                    message: "Waiting for g-force data",
                    minHeight: 140
                )
                .frame(height: 150)
            } else {
                let samples = gForceSamples
                let latestId = samples.last?.id
                Chart {
                    ForEach(tractionCircleBoundaryPoints) { point in
                        LineMark(
                            x: .value("Longitudinal", point.longitudinal),
                            y: .value("Lateral", point.lateral)
                        )
                        .foregroundStyle(.white.opacity(0.18))
                    }
                    
                    RuleMark(x: .value("Zero Longitudinal", 0))
                        .lineStyle(.init(lineWidth: 1, dash: [4]))
                        .foregroundStyle(.white.opacity(0.3))
                    
                    RuleMark(y: .value("Zero Lateral", 0))
                        .lineStyle(.init(lineWidth: 1, dash: [4]))
                        .foregroundStyle(.white.opacity(0.3))
                    
                    ForEach(samples) { sample in
                        PointMark(
                            x: .value("Longitudinal", clampedGForce(sample.longitudinal)),
                            y: .value("Lateral", clampedGForce(sample.lateral))
                        )
                        .symbolSize(sample.id == latestId ? 80 : 28)
                        .foregroundStyle(sample.id == latestId ? selectedTeam.accent : selectedTeam.accent.opacity(0.35))
                    }
                }
                .chartXScale(domain: gForceDomain)
                .chartYScale(domain: gForceDomain)
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(width: 200, height: 150)
            }
        }
    }
    
    @ViewBuilder
    private var statChipRow: some View {
        HStack(spacing: 18) {
            StatChip(
                label: "Gap Ahead",
                value: gapToFrontDisplay,
                color: selectedTeam.speedColor
            )
            StatChip(
                label: "Gap Behind",
                value: gapToBehindDisplay,
                color: selectedTeam.secondaryAccent
            )
            StatChip(
                label: "Penalties",
                value: "+\(viewModel.penaltiesSeconds)s",
                color: viewModel.penaltiesSeconds > 0 ? selectedTeam.brakeColor : .green
            )
            StatChip(
                label: "Total Laps",
                value: totalLaps,
                color: .green
            )
        }
    }
    
    @ViewBuilder
    private var handlingBalanceGraph: some View {
        let frontData = trimmedHistory(viewModel.frontSlipHistory)
        let rearData = trimmedHistory(viewModel.rearSlipHistory)
        let combined = (frontData + rearData).sorted { $0.timestamp < $1.timestamp }
        let fallbackDomain = Date().addingTimeInterval(-chartTimeWindow)...Date()
        
        if combined.isEmpty {
            ChartPlaceholder(
                message: "Waiting for wheel slip data",
                minHeight: 140
            )
        } else {
            Chart {
                ForEach(frontData) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Slip", clampedSlip(point.value))
                    )
                    .foregroundStyle(by: .value("Axle", "Front"))
                    .interpolationMethod(.catmullRom)
                }
                
                ForEach(rearData) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Slip", clampedSlip(point.value))
                    )
                    .foregroundStyle(by: .value("Axle", "Rear"))
                    .interpolationMethod(.catmullRom)
                }
                
                RuleMark(y: .value("Neutral", 0))
                    .lineStyle(.init(lineWidth: 1, dash: [5]))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .chartForegroundStyleScale([
                "Front": selectedTeam.throttleColor,
                "Rear": selectedTeam.brakeColor
            ])
            .chartXScale(domain: chartDomain(for: combined) ?? fallbackDomain)
            .chartYScale(domain: -1.0...1.0)
            .chartYAxis {
                AxisMarks(values: [-1, -0.5, 0, 0.5, 1])
            }
            .chartLegend(position: .bottom)
        }
    }
    
    private var damageSection: some View {
        TelemetryCard {
            HStack(alignment: .top, spacing: 24) {

                rpmGaugeView
                
                Divider()
                    .background(Color.white.opacity(0.12))

                VStack(spacing: 16) {
                    tyreDamageRow(front: true)
                    
                    HStack {
                        Spacer(minLength: 0)
                        damageChip(label: "Engine", value: Double(viewModel.engineDamagePercent))
                        Spacer(minLength: 0)
                    }
                    
                    tyreDamageRow(front: false)
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }
    
    @ViewBuilder
    private func speedChartBlock(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Speed", systemImage: "speedometer")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
            
            let data = trimmedHistory(viewModel.speedHistory)
            
            if data.isEmpty {
                ChartPlaceholder(minHeight: height)
            } else if let domain = chartDomain(for: data) {
                Chart {
                    ForEach(data) { point in
                        AreaMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Speed", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            .linearGradient(
                                colors: [selectedTeam.speedColor.opacity(0.35), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Speed", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(selectedTeam.speedColor)
                        .lineStyle(.init(lineWidth: 3))
                    }
                }
                .chartXScale(domain: domain)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis(.hidden)
                .frame(height: height)
            } else {
                ChartPlaceholder(minHeight: height)
            }
        }
    }
    
    @ViewBuilder
    private func inputChart(
        for history: [TelemetryPoint],
        label: String,
        icon: String,
        color: Color,
        height: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(label, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
            
            let data = trimmedHistory(history)
            
            if data.isEmpty {
                ChartPlaceholder(
                    message: "Waiting for \(label.lowercased()) data",
                    minHeight: height
                )
            } else if let domain = chartDomain(for: data) {
                Chart {
                    ForEach(data) { point in
                        AreaMark(
                            x: .value("Time", point.timestamp),
                            y: .value(label, point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.linearGradient(
                            colors: [color.opacity(0.28), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value(label, point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .lineStyle(.init(lineWidth: 2.5))
                        .foregroundStyle(color)
                    }
                }
                .chartXScale(domain: domain)
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: Array(stride(from: 0, through: 100, by: 25)))
                }
                .chartXAxis(.hidden)
                .frame(height: height)
            } else {
                ChartPlaceholder(
                    message: "Waiting for \(label.lowercased()) data",
                    minHeight: height
                )
            }
        }
    }
    
    private struct DashboardLayoutMetrics {
        let size: CGSize
        let usesWideLayout: Bool
        let cardSpacing: CGFloat
        let horizontalPadding: CGFloat
        let verticalPadding: CGFloat
        let primaryChartHeight: CGFloat
        let inputChartHeight: CGFloat
        
        init(size: CGSize) {
            let safeHeight = max(size.height, 400)
            self.size = size
            self.usesWideLayout = size.width >= 900
            self.cardSpacing = usesWideLayout ? 28 : 20
            self.horizontalPadding = max(20, size.width * 0.04)
            self.verticalPadding = max(16, safeHeight * 0.04)
            let basePrimary = safeHeight * (usesWideLayout ? 0.26 : 0.22)
            let uniformHeight = min(max(basePrimary, 140), 260) * 0.75
            self.primaryChartHeight = uniformHeight
            self.inputChartHeight = uniformHeight
        }
    }
    
    // MARK: - Helpers
    
    private var gearDisplay: String {
        switch viewModel.gear {
        case 0: return "N"
        case -1: return "R"
        default: return "G\(viewModel.gear)"
        }
    }
    
    private var currentRPMValue: Double {
        sanitizedGaugeValue(viewModel.rpm)
    }
    
    private var rpmGaugeMax: Double {
        max(10000, viewModel.maxRPM)
    }
    
    private let gForceLimit: Double = 4.5
    
    private var gForceDomain: ClosedRange<Double> {
        -gForceLimit...gForceLimit
    }
    
    private var tractionUtilization: Double {
        let magnitude = hypot(viewModel.gLat, viewModel.gLong)
        return min(1.0, max(0, magnitude / gForceLimit))
    }
    
    private var tractionUtilizationDisplay: String {
        String(format: "%.0f%%", tractionUtilization * 100)
    }
    
    private var gForceSamples: [GForceSample] {
        let latHistory = trimmedHistory(viewModel.lateralGHistory)
        let longHistory = trimmedHistory(viewModel.longitudinalGHistory)
        let count = min(latHistory.count, longHistory.count)
        guard count > 0 else { return [] }
        return (0..<count).map { index in
            GForceSample(
                id: latHistory[index].id,
                timestamp: latHistory[index].timestamp,
                lateral: latHistory[index].value,
                longitudinal: longHistory[index].value
            )
        }
    }

    private var totalLaps: String {
        return "\(viewModel.totalLapsSession)"
    }
    
    private var tractionCircleBoundaryPoints: [TractionBoundaryPoint] {
        stride(from: 0.0, through: 360.0, by: 12.0).map { angle in
            let radians = angle * .pi / 180
            return TractionBoundaryPoint(
                angle: angle,
                lateral: sin(radians) * gForceLimit,
                longitudinal: cos(radians) * gForceLimit
            )
        }
    }
    
    private var damageMetrics: [DamageMetric] {
        [
            DamageMetric(label: "Front Wing", value: Double(viewModel.frontWingDamage)),
            DamageMetric(label: "Rear Wing", value: Double(viewModel.rearWingDamage)),
            DamageMetric(label: "Floor", value: Double(viewModel.floorDamage)),
            DamageMetric(label: "Diffuser", value: Double(viewModel.diffuserDamage)),
            DamageMetric(label: "Sidepods", value: Double(viewModel.sidepodDamage)),
            DamageMetric(label: "Gearbox", value: Double(viewModel.gearBoxDamage)),
            DamageMetric(label: "Engine", value: Double(viewModel.engineDamagePercent))
        ]
    }
    
    private var structuralDamageMetrics: [DamageMetric] {
        damageMetrics.filter { metric in
            ["Floor", "Sidepods", "Gearbox", "Diffuser"].contains(metric.label)
        }
    }
    
    private func tyreDamageValue(at index: Int) -> Double {
        guard viewModel.tyreDamage.indices.contains(index) else { return 0 }
        return Double(viewModel.tyreDamage[index])
    }
    
    private func tyreDamageRow(front: Bool) -> some View {
        HStack(spacing: 12) {
            if front {
                damageChip(label: "Front Left", value: tyreDamageValue(at: 2))
                damageChip(label: "Front Wing", value: Double(viewModel.frontWingDamage))
                damageChip(label: "Front Right", value: tyreDamageValue(at: 3))
            } else {
                damageChip(label: "Rear Left", value: tyreDamageValue(at: 0))
                damageChip(label: "Rear Wing", value: Double(viewModel.rearWingDamage))
                damageChip(label: "Rear Right", value: tyreDamageValue(at: 1))
            }
        }
    }
    
    private func damageChip(label: String, value: Double) -> some View {
        StatChip(
            label: label,
            value: "\(Int(value))%",
            color: damageColor(for: value)
        )
        .frame(maxWidth: .infinity)
    }
    
    private func sanitizedGaugeValue(_ value: Double) -> Double {
        if value.isNaN || value.isInfinite {
            return 0
        }
        return max(value, 0)
    }
    
    private func clampedSlip(_ value: Double) -> Double {
        if value.isNaN || value.isInfinite {
            return 0
        }
        return min(1, max(-1, value))
    }
    
    private func clampedGForce(_ value: Double) -> Double {
        if value.isNaN || value.isInfinite {
            return 0
        }
        return min(gForceLimit, max(-gForceLimit, value))
    }
    
    private var gapToFrontDisplay: String {
        let trimmed = viewModel.deltaToFront.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "+0.000" : trimmed
    }
    
    private var gapToBehindDisplay: String {
        let trimmed = viewModel.deltaToBehind.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "+0.000" : trimmed
    }
    
    private var gForceMagnitude: String {
        let magnitude = hypot(viewModel.gLat, viewModel.gLong)
        return String(format: "%.2f g", magnitude)
    }
    
    private func damageColor(for value: Double) -> Color {
        switch value {
        case ..<15:
            return Color.green
        case ..<35:
            return Color.yellow
        case ..<60:
            return Color.orange
        default:
            return selectedTeam.brakeColor
        }
    }
    
    private func trimmedHistory(_ history: [TelemetryPoint]) -> [TelemetryPoint] {
        guard let latestTimestamp = history.last?.timestamp else {
            return []
        }
        
        let cutoff = latestTimestamp.addingTimeInterval(-chartTimeWindow)
        guard let startIndex = history.firstIndex(where: { $0.timestamp >= cutoff }) else {
            return history
        }
        
        return Array(history[startIndex...])
    }

    private func safetyCarLabel(for status: UInt8) -> String {
        switch status {
        case 1: return "Full Safety Car"
        case 2: return "Virtual Safety Car"
        case 3: return "Formation Lap"
        default: return "Neutralized track"
        }
    }

    private func handlingColor(for state: HandlingBalanceState) -> Color {
        switch state {
        case .neutral:
            return .green
        case .understeer:
            return selectedTeam.brakeColor
        case .oversteer:
            return selectedTeam.throttleColor
        }
    }

    private func chartDomain(for history: [TelemetryPoint]) -> ClosedRange<Date>? {
        guard
            let firstTimestamp = history.first?.timestamp,
            let latestTimestamp = history.last?.timestamp
        else {
            return nil
        }
        
        let windowStart = latestTimestamp.addingTimeInterval(-chartTimeWindow)
        let start = max(firstTimestamp, windowStart)
        return start...latestTimestamp
    }
}

private struct DamageFillBar: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(Int(value))%")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(color)
            }
            
            GeometryReader { proxy in
                let clamped = min(max(value / 100, 0), 1)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(color.opacity(0.85))
                            .frame(width: proxy.size.width * clamped),
                        alignment: .leading
                    )
            }
            .frame(height: 14)
        }
        .padding(.vertical, 6)
    }
}

private struct DamageMetric: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

private struct GForceSample: Identifiable {
    let id: UUID
    let timestamp: Date
    let lateral: Double
    let longitudinal: Double
}

private struct TractionBoundaryPoint: Identifiable {
    let id = UUID()
    let angle: Double
    let lateral: Double
    let longitudinal: Double
}

extension Int {
    var roundedWithAbbreviations: String {
        let number = Double(self)
        let thousand = number / 1000
        let million = number / 1000000
        if million >= 1.0 {
            return "\(round(million*10)/10)M"
        }
        else if thousand >= 1.0 {
            return "\(round(thousand*10)/10)k"
        }
        else {
            return "\(self)"
        }
    }
}
