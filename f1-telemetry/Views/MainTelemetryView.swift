//
//  MainTelemetryView.swift
//  f1-telemetry
//
//  Created by Andrés on 10/10/2025.
//

import SwiftUI

struct MainTelemetryView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    
    var body: some View {
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
            InputsView(viewModel: viewModel)
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
}


