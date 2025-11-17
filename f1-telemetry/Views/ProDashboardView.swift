//
//  ProDashboardView.swift
//  f1-telemetry
//
//  Created by Cursor on 11/17/2025.
//

import SwiftUI
import Charts

struct ProDashboardView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                LazyVGrid(columns: gridColumns, spacing: 24) {
                    speedSection
                    inputsSection
                    gForceSection
                    powerUnitSection
                }
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 32)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 6 / 255, green: 8 / 255, blue: 16 / 255),
                    Color(red: 9 / 255, green: 13 / 255, blue: 26 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
    
    // MARK: - Sections
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Oracle Dashboard")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("Live telemetry focus on driver inputs & chassis balance")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.65))
            
            HStack(spacing: 12) {
                MetricPill(
                    title: "Speed",
                    value: "\(Int(viewModel.speed.safeInt())) km/h",
                    accent: .yellow
                )
                MetricPill(
                    title: "Gear",
                    value: gearDisplay,
                    accent: .orange
                )
                MetricPill(
                    title: "G-Force",
                    value: String(format: "%.2fg", hypot(viewModel.gLat, viewModel.gLong)),
                    accent: .pink
                )
            }
        }
    }
    
    private var speedSection: some View {
        TelemetryCard(
            title: "Speed Trace",
            caption: "History vs live",
            icon: "speedometer"
        ) {
            if viewModel.speedHistory.isEmpty {
                ChartPlaceholder()
            } else {
                Chart {
                    ForEach(viewModel.speedHistory) { point in
                        AreaMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Speed", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.linearGradient(
                            colors: [Color.yellow.opacity(0.35), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Speed", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.yellow)
                        .lineStyle(.init(lineWidth: 3))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis(.hidden)
                .frame(height: 220)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            HStack {
                StatChip(label: "Current", value: "\(Int(viewModel.speed)) km/h", color: .yellow)
                StatChip(label: "Average (30s)", value: avgSpeed, color: .blue)
            }
        }
    }
    
    private var inputsSection: some View {
        TelemetryCard(
            title: "Throttle / Brake",
            caption: "Driver inputs (%)",
            icon: "chart.line.uptrend.xyaxis"
        ) {
            if viewModel.throttleHistory.isEmpty && viewModel.brakeHistory.isEmpty {
                ChartPlaceholder()
            } else {
                Chart {
                    ForEach(viewModel.throttleHistory) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Throttle", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.green)
                        .lineStyle(.init(lineWidth: 2.5))
                    }
                    
                    ForEach(viewModel.brakeHistory) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Brake", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.red)
                        .lineStyle(.init(lineWidth: 2.5))
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: Array(stride(from: 0, through: 100, by: 25)))
                }
                .chartXAxis(.hidden)
                .frame(height: 220)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            HStack(spacing: 12) {
                StatChip(label: "Throttle", value: "\(Int(viewModel.throttle))%", color: .green)
                StatChip(label: "Brake", value: "\(Int(viewModel.brake))%", color: .red)
                StatChip(label: "Steer", value: String(format: "%.1f°", viewModel.steer), color: .cyan)
            }
        }
    }
    
    private var gForceSection: some View {
        TelemetryCard(
            title: "G-Force Envelope",
            caption: "Chassis balance",
            icon: "circle.grid.cross"
        ) {
            if viewModel.lateralGHistory.isEmpty && viewModel.longitudinalGHistory.isEmpty {
                ChartPlaceholder()
            } else {
                Chart {
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(.white.opacity(0.2))
                    ForEach(viewModel.lateralGHistory) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Lat G", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.orange)
                    }
                    
                    ForEach(viewModel.longitudinalGHistory) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Long G", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.blue)
                    }
                }
                .chartYScale(domain: -5...5)
                .chartYAxis {
                    AxisMarks(values: Array(stride(from: -5.0, through: 5.0, by: 2.5)))
                }
                .chartXAxis(.hidden)
                .frame(height: 220)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            HStack(spacing: 12) {
                StatChip(label: "Lat", value: String(format: "%.2f g", viewModel.gLat), color: .orange)
                StatChip(label: "Long", value: String(format: "%.2f g", viewModel.gLong), color: .blue)
                StatChip(label: "Vert", value: String(format: "%.2f g", viewModel.gVert), color: .pink)
            }
        }
    }
    
    private var powerUnitSection: some View {
        TelemetryCard(
            title: "Power Unit",
            caption: "RPM • DRS • ERS",
            icon: "dial.medium"
        ) {
            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Gauge(value: min(viewModel.rpm, viewModel.maxRPM), in: 0...max(viewModel.maxRPM, 1)) {
                        Text("RPM")
                    } currentValueLabel: {
                        Text("\(Int(viewModel.rpm))")
                            .font(.system(.title3, design: .rounded).monospacedDigit())
                            .foregroundStyle(.white)
                    }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(Gradient(colors: [.green, .yellow, .orange, .red]))
                    .scaleEffect(1.2)
                    
                    Text("Shift at \(Int(viewModel.maxRPM)) rpm")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Divider()
                    .frame(height: 120)
                    .overlay(Color.white.opacity(0.1))
                
                VStack(alignment: .leading, spacing: 12) {
                    StatChip(label: "Gear", value: gearDisplay, color: .orange)
                    StatChip(label: "ERS", value: String(format: "%.1f kJ", viewModel.ersStoreEnergy / 1000), color: .purple)
                    StatChip(label: "DRS", value: viewModel.drsActive ? "Armed" : (viewModel.drsAvailable ? "Available" : "Closed"), color: viewModel.drsActive ? .green : .gray)
                }
            }
            .frame(maxWidth: .infinity)
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
    
    private var avgSpeed: String {
        guard viewModel.speedHistory.count > 4 else { return "-- km/h" }
        let subset = viewModel.speedHistory.suffix(60)
        let avg = subset.map(\.value).reduce(0, +) / Double(subset.count)
        return "\(Int(avg)) km/h"
    }
}

// MARK: - Building Blocks

private struct TelemetryCard<Content: View>: View {
    let title: String
    let caption: String
    let icon: String
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(title, systemImage: icon)
                    .labelStyle(.titleAndIcon)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(caption.uppercased())
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
            }
            
            content
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

private struct MetricPill: View {
    let title: String
    let value: String
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.35),
                            accent.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accent.opacity(0.4), lineWidth: 1)
        )
    }
}

private struct StatChip: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption2)
                .foregroundStyle(color.opacity(0.7))
            Text(value)
                .font(.system(.body, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

private struct ChartPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
            Text("Waiting for live telemetry")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }
}

