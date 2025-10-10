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
        let _ = print("🎨 ContentView body rendering - Speed: \(viewModel.speed), Connected: \(viewModel.isConnected), Packets: \(viewModel.packetsReceived)")
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.15)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // Top Header - Connection status, session, network details
                    headerView
                        .frame(height: 50)
                    
                    // Main 2-column layout
                    HStack(spacing: 12) {
                        // Left Column (40%) - Engine/Fuel, Lap Times, Tyres
                        VStack(spacing: 12) {
                            engineFuelView
                            lapInfoView
                            tyreTemperaturesView
                        }
                        .frame(width: (geometry.size.width - 36) * 0.40)
                        
                        // Right Column (60%) - Speed, Gear, RPM, Inputs, Lap #, Position
                        VStack(spacing: 12) {
                            mainTelemetryView
                        }
                        .frame(width: (geometry.size.width - 36) * 0.60)
                    }
                }
                .padding(12)
            }
        }
        .onAppear {
            print("🎨 ContentView appeared - starting listener")
            viewModel.startListening()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack(spacing: 16) {
            // Connection status
            HStack(spacing: 6) {
                Image(systemName: "circle.fill")
                    .foregroundColor(viewModel.isConnected ? .green : .red)
                    .font(.system(size: 8))
                
                Text(viewModel.isConnected ? "Connected" : "Waiting...")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(viewModel.isConnected ? .green : .orange)
            }
            
            // Packets
            Label("\(viewModel.packetsReceived)", systemImage: "antenna.radiowaves.left.and.right")
                .font(.system(size: 10))
                .foregroundColor(.gray)
            
            // Session
            HStack(spacing: 3) {
                Image(systemName: "number.circle")
                    .font(.system(size: 10))
                    .foregroundColor(.cyan)
                Text(viewModel.sessionUID)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.cyan)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            
            Spacer()
            
            // Network info - compact
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "network")
                        .font(.system(size: 9))
                        .foregroundColor(.blue)
                    Text(viewModel.localIPAddress)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                
                HStack(spacing: 4) {
                    Text("Port:")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                    Text("\(viewModel.port)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Main Telemetry View
    
    private var mainTelemetryView: some View {
        VStack(spacing: 12) {
            // Lap and Position info
            HStack(spacing: 16) {
                // Position - Large and prominent
                HStack(spacing: 8) {
                    Text("Position")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    Text("P\(viewModel.position)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                // Lap number
                HStack(spacing: 8) {
                    Text("Lap")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    Text("\(viewModel.currentLap)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
            
            // Speed - Large and prominent
            VStack(spacing: 4) {
                Text("\(viewModel.speed.safeInt())")
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
            HStack(spacing: 12) {
                // Gear
                VStack(spacing: 6) {
                    Text(gearDisplay)
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundColor(gearColor)
                    
                    Text("GEAR")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                // RPM
                VStack(spacing: 6) {
                    Text("\(viewModel.rpm.safeInt())")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
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
                .padding(12)
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
            VStack(spacing: 6) {
                Text("\(viewModel.throttle.safeInt())%")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
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
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            // Brake
            VStack(spacing: 6) {
                Text("\(viewModel.brake.safeInt())%")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
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
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            // Steering
            VStack(spacing: 6) {
                Text("\((viewModel.steer * 100).safeInt())")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
                
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .cornerRadius(4)
                    
                    GeometryReader { geometry in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 18, height: 18)
                            .position(
                                x: geometry.size.width / 2 + CGFloat(viewModel.steer) * (geometry.size.width / 2 - 9),
                                y: geometry.size.height / 2
                            )
                    }
                }
                
                Text("Steering")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .frame(height: 110)
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Lap Info View
    
    private var lapInfoView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("LAP TIMES")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if viewModel.drsAvailable {
                    HStack(spacing: 3) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(viewModel.drsActive ? .green : .yellow)
                        Text("DRS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(viewModel.drsActive ? .green : .yellow)
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            VStack(spacing: 8) {
                lapTimeItem(title: "Current", time: viewModel.currentLapTime, color: .blue)
                lapTimeItem(title: "Last Lap", time: viewModel.lastLapTime, color: .green)
                lapTimeItem(title: "Sector 1", time: viewModel.sector1Time, color: .purple)
                lapTimeItem(title: "Sector 2", time: viewModel.sector2Time, color: .orange)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    Text("Delta")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Spacer()
                    Text(viewModel.deltaToLeader)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                }
                
                HStack {
                    Image(systemName: "road.lanes")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                    Text("Distance")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(viewModel.lapDistance.safeInt()) m")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func lapTimeItem(title: String, time: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            Text(time)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
    }
    
    // MARK: - Engine & Fuel View
    
    private var engineFuelView: some View {
        VStack(spacing: 10) {
            Text("ENGINE & FUEL")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            VStack(spacing: 8) {
                // Fuel
                HStack {
                    Image(systemName: "fuelpump.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("Fuel")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(String(format: "%.1f", viewModel.fuelInTank)) kg")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text("\(String(format: "%.1f", viewModel.fuelRemainingLaps)) laps")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                    }
                }
                
                // Engine Temp
                HStack {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 10))
                        .foregroundColor(engineTempColor)
                    Text("Engine")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(viewModel.engineTemp.safeInt())°C")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(engineTempColor)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // ERS
                HStack {
                    Image(systemName: "battery.100")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                    Text("ERS")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                    Text(viewModel.ersDeployMode)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.2))
                        .cornerRadius(4)
                    Text("\(String(format: "%.0f", viewModel.ersStoreEnergy)) J")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Tyre Temperatures View
    
    private var tyreTemperaturesView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("TYRES")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(viewModel.tyreCompound)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(tyreCompoundColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(tyreCompoundColor.opacity(0.2))
                    .cornerRadius(4)
                
                Text("\(viewModel.tyreAge) laps")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Tyre temperature visualization
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    tyreView(temp: viewModel.tyreTempFL, label: "FL")
                    Spacer()
                    tyreView(temp: viewModel.tyreTempFR, label: "FR")
                }
                
                HStack(spacing: 12) {
                    tyreView(temp: viewModel.tyreTempRL, label: "RL")
                    Spacer()
                    tyreView(temp: viewModel.tyreTempRR, label: "RR")
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func tyreView(temp: Double, label: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.gray)
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 3)
                    .frame(width: 55, height: 55)
                
                Circle()
                    .fill(tyreTemperatureColor(temp))
                    .frame(width: 49, height: 49)
                
                Text("\(temp.safeInt())°")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
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
}

#Preview {
    ContentView()
}
