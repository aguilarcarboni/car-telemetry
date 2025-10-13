//
//  HeaderView.swift
//  f1-telemetry
//
//  Created by Andrés on 10/10/2025.
//

import SwiftUI

struct HeaderView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    
    var body: some View {
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
}


