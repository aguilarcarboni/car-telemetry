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
    
    var body: some View {
        GeometryReader { proxy in
            let layout = DashboardLayoutMetrics(size: proxy.size)
            
            ZStack {
                LinearGradient(
                    colors: selectedTeam.backgroundGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: layout.cardSpacing) {
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
    
    private var metricsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                MetricPill(
                    title: "Speed",
                    value: "\(Int(viewModel.speed.safeInt())) km/h",
                    accent: selectedTeam.speedColor
                )
                MetricPill(
                    title: "Gear",
                    value: gearDisplay,
                    accent: selectedTeam.accent
                )
                MetricPill(
                    title: "G-Force",
                    value: gForceMagnitude,
                    accent: selectedTeam.gLatColor
                )
                MetricPill(
                    title: "Throttle",
                    value: "\(Int(viewModel.throttle))%",
                    accent: selectedTeam.throttleColor
                )
                MetricPill(
                    title: "Brake",
                    value: "\(Int(viewModel.brake))%",
                    accent: selectedTeam.brakeColor
                )
            }
        }
    }
    
    private var teamSelector: some View {
        TeamThemeMenu()
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
        TelemetryCard {
            VStack(spacing: 18) {
                HStack(spacing: 18) {
                    FillBarMetricCard(
                        title: "Speed",
                        icon: "speedometer",
                        value: currentSpeedValue,
                        color: selectedTeam.speedColor, maxValue: speedGaugeMax,
                        valueLabel: "\(Int(viewModel.speed.safeInt())) km/h"
                    )
                    
                    FillBarMetricCard(
                        title: "Revs",
                        icon: "dial.medium",
                        value: currentRPMValue,
                        color: selectedTeam.accent, maxValue: rpmGaugeMax,
                        valueLabel: "\(Int(viewModel.rpm)) rpm",
                        highlightFractionRange: 0.9...1.0,
                        highlightColor: .red
                    )
                }
                
                Divider().background(Color.white.opacity(0.08))
                
                HStack(spacing: 18) {
                    FillBarMetricCard(
                        title: "Throttle",
                        icon: "bolt.fill",
                        value: viewModel.throttle,
                        color: selectedTeam.throttleColor
                    )
                    
                    FillBarMetricCard(
                        title: "Brake",
                        icon: "hand.raised.fill",
                        value: viewModel.brake,
                        color: selectedTeam.brakeColor
                    )
                }
            }
        }
    }
    
    private var damageSection: some View {
        TelemetryCard {
            HStack(alignment: .top, spacing: 24) {
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
                
                Divider()
                    .background(Color.white.opacity(0.12))
                
                VStack(spacing: 16) {
                    ForEach(structuralDamageMetrics, id: \.label) { metric in
                        DamageFillBar(
                            label: metric.label,
                            value: metric.value,
                            color: damageColor(for: metric.value)
                        )
                    }
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
            
            if viewModel.speedHistory.isEmpty {
                ChartPlaceholder(minHeight: height)
            } else {
                Chart {
                    ForEach(viewModel.speedHistory) { point in
                        AreaMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Speed", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.linearGradient(
                            colors: [selectedTeam.speedColor.opacity(0.35), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Speed", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(selectedTeam.speedColor)
                        .lineStyle(.init(lineWidth: 3))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis(.hidden)
                .frame(height: height)
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
            
            if history.isEmpty {
                ChartPlaceholder(
                    message: "Waiting for \(label.lowercased()) data",
                    minHeight: height
                )
            } else {
                Chart {
                    ForEach(history) { point in
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
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: Array(stride(from: 0, through: 100, by: 25)))
                }
                .chartXAxis(.hidden)
                .frame(height: height)
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
            self.primaryChartHeight = min(max(basePrimary, 140), 260)
            let baseInput = safeHeight * (usesWideLayout ? 0.18 : 0.16)
            self.inputChartHeight = min(max(baseInput, 110), 180)
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
    
    private var currentSpeedValue: Double {
        sanitizedGaugeValue(viewModel.speed)
    }
    
    private var speedGaugeMax: Double {
        let historyPeak = viewModel.speedHistory.map(\.value).max() ?? 0
        return max(320, historyPeak + 20)
    }
    
    private var currentRPMValue: Double {
        sanitizedGaugeValue(viewModel.rpm)
    }
    
    private var rpmGaugeMax: Double {
        max(10000, viewModel.maxRPM)
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
    
    private var tyreDamageMetrics: [DamageMetric] {
        [
            DamageMetric(label: "Front Left", value: tyreDamageValue(at: 2)),
            DamageMetric(label: "Front Right", value: tyreDamageValue(at: 3)),
            DamageMetric(label: "Rear Left", value: tyreDamageValue(at: 0)),
            DamageMetric(label: "Rear Right", value: tyreDamageValue(at: 1))
        ]
    }
    
    private var structuralDamageMetrics: [DamageMetric] {
        damageMetrics.filter { metric in
            ["Floor", "Sidepods", "Gearbox", "Diffuser"].contains(metric.label)
        }
    }
    
    private var mostCriticalDamage: DamageMetric? {
        damageMetrics.max(by: { $0.value < $1.value })
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
    
    private var avgSpeed: String {
        guard viewModel.speedHistory.count > 4 else { return "-- km/h" }
        let subset = viewModel.speedHistory.suffix(60)
        let avg = subset.map(\.value).reduce(0, +) / Double(subset.count)
        return "\(Int(avg)) km/h"
    }
    
    private var avgThrottle: String {
        guard viewModel.throttleHistory.count > 4 else { return "-- %" }
        let subset = viewModel.throttleHistory.suffix(60)
        let avg = subset.map(\.value).reduce(0, +) / Double(subset.count)
        return "\(Int(avg))%"
    }
    
    private var avgBrake: String {
        guard viewModel.brakeHistory.count > 4 else { return "-- %" }
        let subset = viewModel.brakeHistory.suffix(60)
        let avg = subset.map(\.value).reduce(0, +) / Double(subset.count)
        return "\(Int(avg))%"
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
}

// MARK: - Building Blocks

private struct FillBarMetricCard: View {
    let title: String
    let icon: String
    let value: Double
    let maxValue: Double
    let color: Color
    let valueLabel: String?
    let highlightFractionRange: ClosedRange<Double>?
    let highlightColor: Color?
    
    init(
        title: String,
        icon: String,
        value: Double,
        color: Color,
        maxValue: Double = 100,
        valueLabel: String? = nil,
        highlightFractionRange: ClosedRange<Double>? = nil,
        highlightColor: Color? = nil
    ) {
        self.title = title
        self.icon = icon
        self.value = value
        self.color = color
        self.maxValue = maxValue
        self.valueLabel = valueLabel
        self.highlightFractionRange = highlightFractionRange
        self.highlightColor = highlightColor
    }
    
    private var normalizedValue: Double {
        guard maxValue > 0 else { return 0 }
        return min(max(value / maxValue, 0), 1)
    }
    
    private var formattedValue: String {
        valueLabel ?? "\(Int(value))%"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(.caption2.weight(.semibold))
                }
            } icon: {
                Image(systemName: icon)
            }
            .foregroundStyle(.white.opacity(0.85))
            
            GeometryReader { proxy in
                let clamped = normalizedValue
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                    
                    if let range = highlightFractionRange, let highlightColor {
                        let start = max(0, min(1, range.lowerBound))
                        let end = max(start, min(1, range.upperBound))
                        let width = proxy.size.width * (end - start)
                        
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(highlightColor.opacity(0.4))
                            .frame(width: width)
                            .offset(x: proxy.size.width * start)
                    }
                    
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    color,
                                    color.opacity(0.4)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * clamped)
                }
            }
            .frame(height: 34)
            
            Text(formattedValue)
                .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(color)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(color.opacity(0.35), lineWidth: 1)
        )
    }
}

private struct DamageProgressRow: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text("\(Int(value))%")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(color)
            }
            
            GeometryReader { proxy in
                let clamped = min(max(value / 100, 0), 1)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.8))
                        .frame(width: proxy.size.width * clamped)
                }
            }
            .frame(height: 10)
        }
        .padding(.vertical, 4)
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

