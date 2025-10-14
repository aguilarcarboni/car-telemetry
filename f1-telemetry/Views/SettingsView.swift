//
//  SettingsView.swift
//  f1-telemetry
//
//  Created by Andrés on 10/10/2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    
    var body: some View {
        List {
            Section(header: 
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(viewModel.isConnected ? .green : .red)
                    .font(.system(size: 8))
                Text("Connection")
            }
            ) {

                HStack(spacing: 4) {
                    Image(systemName: "network")
                        .font(.system(size: 9))
                        .foregroundColor(.blue)
                    Text("(\(viewModel.localIPAddress):\(viewModel.port))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }

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
            }
        }
    }
}

#Preview {
    SettingsView(viewModel: TelemetryViewModel())
}


