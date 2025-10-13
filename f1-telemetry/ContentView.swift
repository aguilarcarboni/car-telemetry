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
                    HeaderView(viewModel: viewModel)
                        .frame(height: 50)
                    
                    // Main 2-column layout
                    HStack(spacing: 12) {
                        // Left Column (40%) - Engine/Fuel, Lap Times, Tyres
                        VStack(spacing: 12) {
                            EngineFuelView(viewModel: viewModel)
                            LapInfoView(viewModel: viewModel)
                            TyreTemperaturesView(viewModel: viewModel)
                        }
                        .frame(width: (geometry.size.width - 36) * 0.40)
                        
                        // Right Column (60%) - Speed, Gear, RPM, Inputs, Lap #, Position
                        VStack(spacing: 12) {
                            MainTelemetryView(viewModel: viewModel)
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
}

#Preview {
    ContentView()
}
