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
}


