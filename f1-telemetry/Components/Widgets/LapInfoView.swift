//
//  LapInfoView.swift
//  f1-telemetry
//
//  Created by Andrés on 10/10/2025.
//

import SwiftUI

struct LapInfoView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    
    var body: some View {
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
                lapTimeItem(title: "Sector 1", time: viewModel.sector1Time)
                lapTimeItem(title: "Sector 2", time: viewModel.sector2Time)
                lapTimeItem(title: "Last", time: viewModel.lastLapTime, color: .green)
                lapTimeItem(title: "Current", time: viewModel.currentLapTime, color: .blue)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    Text("Delta Front")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Spacer()
                    Text(viewModel.deltaToFront)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                }

                HStack {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    Text("Delta Leader")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Spacer()
                    Text(viewModel.deltaToLeader)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func lapTimeItem(title: String, time: String, color: Color? = .white) -> some View {
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
}


