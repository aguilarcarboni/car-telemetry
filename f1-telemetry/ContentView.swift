//
//  ContentView.swift
//  f1-tracker
//
//  Created by Andrés on 9/10/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TelemetryViewModel()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.15)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerView
                    
                    // Main telemetry section
                    mainTelemetryView
                    
                    // Lap information
                    lapInfoView
                    
                    // Engine & Fuel
                    engineFuelView
                    
                    // Tyre temperatures
                    tyreTemperaturesView
                    
                    // Additional data
                    additionalDataView
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.startListening()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(viewModel.isConnected ? .green : .red)
                    .font(.system(size: 12))
                
                Text(viewModel.isConnected ? "Connected" : "Waiting for telemetry...")
                    .font(.headline)
                    .foregroundColor(viewModel.isConnected ? .green : .orange)
                
                Spacer()
                
                Text("P\(viewModel.position)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            }
            
            HStack {
                Label("\(viewModel.packetsReceived) packets", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("Lap \(viewModel.currentLap)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Main Telemetry View
    
    private var mainTelemetryView: some View {
        VStack(spacing: 16) {
            // Speed - Large and prominent
            VStack(spacing: 4) {
                Text("\(Int(viewModel.speed))")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("KM/H")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.3), Color.purple.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            
            // Gear and RPM
            HStack(spacing: 16) {
                // Gear
                VStack(spacing: 8) {
                    Text(gearDisplay)
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundColor(gearColor)
                    
                    Text("GEAR")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                // RPM
                VStack(spacing: 8) {
                    Text("\(Int(viewModel.rpm))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(rpmColor)
                    
                    Text("RPM")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    // RPM Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                            
                            Rectangle()
                                .fill(rpmGradient)
                                .frame(width: geometry.size.width * CGFloat(min(viewModel.rpm / viewModel.maxRPM, 1.0)))
                        }
                    }
                    .frame(height: 8)
                    .cornerRadius(4)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
            
            // Inputs (Throttle, Brake, Steering)
            inputsView
        }
    }
    
    // MARK: - Inputs View
    
    private var inputsView: some View {
        HStack(spacing: 12) {
            // Throttle
            VStack(spacing: 8) {
                Text("\(Int(viewModel.throttle))%")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                        
                        Rectangle()
                            .fill(Color.green)
                            .frame(height: geometry.size.height * CGFloat(viewModel.throttle / 100))
                    }
                }
                .cornerRadius(4)
                
                Text("Throttle")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            // Brake
            VStack(spacing: 8) {
                Text("\(Int(viewModel.brake))%")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.red)
                
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                        
                        Rectangle()
                            .fill(Color.red)
                            .frame(height: geometry.size.height * CGFloat(viewModel.brake / 100))
                    }
                }
                .cornerRadius(4)
                
                Text("Brake")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            // Steering
            VStack(spacing: 8) {
                Text("\(Int(viewModel.steer * 100))")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
                
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .cornerRadius(4)
                    
                    GeometryReader { geometry in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 20, height: 20)
                            .position(
                                x: geometry.size.width / 2 + CGFloat(viewModel.steer) * (geometry.size.width / 2 - 10),
                                y: geometry.size.height / 2
                            )
                    }
                }
                
                Text("Steering")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .frame(height: 120)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Lap Info View
    
    private var lapInfoView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("LAP TIMES")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if viewModel.drsAvailable {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(viewModel.drsActive ? .green : .yellow)
                        Text("DRS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(viewModel.drsActive ? .green : .yellow)
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack {
                lapTimeItem(title: "Current", time: viewModel.currentLapTime, color: .blue)
                lapTimeItem(title: "Last Lap", time: viewModel.lastLapTime, color: .green)
            }
            
            HStack {
                lapTimeItem(title: "Sector 1", time: viewModel.sector1Time, color: .purple)
                lapTimeItem(title: "Sector 2", time: viewModel.sector2Time, color: .orange)
            }
            
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundColor(.yellow)
                Text("Delta to Leader:")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Spacer()
                Text(viewModel.deltaToLeader)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func lapTimeItem(title: String, time: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
            
            Text(time)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Engine & Fuel View
    
    private var engineFuelView: some View {
        VStack(spacing: 12) {
            Text("ENGINE & FUEL")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack(spacing: 16) {
                // Fuel
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "fuelpump.fill")
                            .foregroundColor(.orange)
                        Text("Fuel")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Text("\(String(format: "%.1f", viewModel.fuelInTank)) kg")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text("\(String(format: "%.1f", viewModel.fuelRemainingLaps)) laps left")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Engine Temp
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "thermometer.medium")
                            .foregroundColor(engineTempColor)
                        Text("Engine")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Text("\(Int(viewModel.engineTemp))°C")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(engineTempColor)
                    
                    Text("Temperature")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // ERS
            HStack {
                Image(systemName: "battery.100")
                    .foregroundColor(.green)
                Text("ERS:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                Text("\(String(format: "%.0f", viewModel.ersStoreEnergy)) J")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                Spacer()
                Text(viewModel.ersDeployMode)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.2))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Tyre Temperatures View
    
    private var tyreTemperaturesView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("TYRES")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(viewModel.tyreCompound)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(tyreCompoundColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tyreCompoundColor.opacity(0.2))
                    .cornerRadius(6)
                
                Text("\(viewModel.tyreAge) laps")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Tyre temperature visualization
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    tyreView(temp: viewModel.tyreTempFL, label: "FL")
                    Spacer()
                    tyreView(temp: viewModel.tyreTempFR, label: "FR")
                }
                
                HStack(spacing: 20) {
                    tyreView(temp: viewModel.tyreTempRL, label: "RL")
                    Spacer()
                    tyreView(temp: viewModel.tyreTempRR, label: "RR")
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func tyreView(temp: Double, label: String) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .fill(tyreTemperatureColor(temp))
                    .frame(width: 62, height: 62)
                
                Text("\(Int(temp))°")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Additional Data View
    
    private var additionalDataView: some View {
        VStack(spacing: 12) {
            Text("ADDITIONAL INFO")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack {
                dataItem(icon: "road.lanes", label: "Lap Distance", value: "\(Int(viewModel.lapDistance)) m")
                dataItem(icon: "clock.fill", label: "Last Update", value: timeAgo(viewModel.lastUpdateTime))
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func dataItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Helper Computed Properties
    
    private var gearDisplay: String {
        switch viewModel.gear {
        case 0: return "N"
        case -1: return "R"
        default: return "\(viewModel.gear)"
        }
    }
    
    private var gearColor: Color {
        if viewModel.gear <= 0 {
            return .orange
        } else if viewModel.gear >= 7 {
            return .red
        } else {
            return .white
        }
    }
    
    private var rpmColor: Color {
        let percentage = viewModel.rpm / viewModel.maxRPM
        if percentage > 0.95 {
            return .red
        } else if percentage > 0.85 {
            return .orange
        } else {
            return .white
        }
    }
    
    private var rpmGradient: LinearGradient {
        let percentage = viewModel.rpm / viewModel.maxRPM
        if percentage > 0.9 {
            return LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [.green, .yellow], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    private var engineTempColor: Color {
        if viewModel.engineTemp > 110 {
            return .red
        } else if viewModel.engineTemp > 100 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var tyreCompoundColor: Color {
        switch viewModel.tyreCompound {
        case "Soft": return .red
        case "Medium": return .yellow
        case "Hard": return .white
        case "Inter": return .green
        case "Wet": return .blue
        default: return .gray
        }
    }
    
    private func tyreTemperatureColor(_ temp: Double) -> Color {
        if temp > 100 {
            return .red
        } else if temp > 85 {
            return .orange
        } else if temp > 70 {
            return .green
        } else {
            return .blue
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 2 {
            return "now"
        } else {
            return "\(seconds)s ago"
        }
    }
}

#Preview {
    ContentView()
}
