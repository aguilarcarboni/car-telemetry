//
//  TyreTemperaturesView.swift
//  f1-telemetry
//
//  Created by Andrés on 10/10/2025.
//

import SwiftUI

struct TyreTemperaturesView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    
    var body: some View {
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

