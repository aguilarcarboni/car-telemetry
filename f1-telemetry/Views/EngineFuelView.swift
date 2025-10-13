//
//  EngineFuelView.swift
//  f1-telemetry
//
//  Created by Andrés on 10/10/2025.
//

import SwiftUI

struct EngineFuelView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    
    var body: some View {
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
    
    private var engineTempColor: Color {
        if viewModel.engineTemp > 110 {
            return .red
        } else if viewModel.engineTemp > 100 {
            return .orange
        } else {
            return .green
        }
    }
}


