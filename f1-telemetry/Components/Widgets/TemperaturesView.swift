//
//  TemperaturesView.swift
//  f1-telemetry
//
//  Created by Andrés on 10/10/2025.
//

import SwiftUI

struct TemperaturesView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("TEMPERATURES")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)

                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Temperature visualization (surface, inner, brakes) with central engine temp
            ZStack {
                // Four wheels
                VStack(spacing: 50) {
                    HStack(spacing: 50) {
                        wheelTempView(surface: viewModel.tyreTempFL,
                                       brake: viewModel.brakeTempFL, left: true)
                        wheelTempView(surface: viewModel.tyreTempFR,
                                       brake: viewModel.brakeTempFR, left: false)
                    }
                    
                    HStack(spacing: 50) {
                        wheelTempView(surface: viewModel.tyreTempRL,
                                       brake: viewModel.brakeTempRL, left: true)
                        wheelTempView(surface: viewModel.tyreTempRR,
                                       brake: viewModel.brakeTempRR, left: false)
                    }
                }
                // Center engine temperature
                engineTempView(temp: viewModel.engineTemp)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func wheelTempView(surface: Double, brake: Double, left: Bool) -> some View {
        VStack(spacing: 6) {
            
            // Representation of tyre (surface) and brake temperature
            HStack(alignment: .center , spacing: 8) {

                if left {
                    // Temperature values displayed to the left of the circles
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(surface.safeInt())°")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text("\(brake.safeInt())°")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                ZStack {
                    // Outer - Surface temperature ring
                    Circle()
                        .stroke(tyreTemperatureColor(surface), lineWidth: 6)
                        .frame(width: 55, height: 55)
                    // Inner - Brake temperature fill
                    Circle()
                        .fill(tyreTemperatureColor(brake))
                        .frame(width: 24, height: 24)
                }
                if !left {
                    // Temperature values displayed to the right of the circles
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(surface.safeInt())°")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text("\(brake.safeInt())°")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
    }
    
    private func engineTempView(temp: Double) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 3)
                .frame(width: 60, height: 60)
            Circle()
                .fill(tyreTemperatureColor(temp))
                .frame(width: 54, height: 54)
            VStack(spacing: 2) {
                Text("\(temp.safeInt())°")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
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

