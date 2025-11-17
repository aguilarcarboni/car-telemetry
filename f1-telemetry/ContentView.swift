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
        TabView {
            Tab("Dashboard", systemImage: "speedometer") {
                ProDashboardView(viewModel: viewModel)
            }
            
            Tab("Overview", systemImage: "car.fill") {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        SessionInfoView(viewModel: viewModel)
                        WeatherView(viewModel: viewModel)
                    }
                    InputsView(viewModel: viewModel)
                    HStack(spacing: 12) {
                        TemperaturesView(viewModel: viewModel)
                        TyresView(viewModel: viewModel)
                        LapInfoView(viewModel: viewModel)
                        DamageView(viewModel: viewModel)
                    }

                }
                .padding(.horizontal, 50)
            }
            Tab("Sessions", systemImage: "clock") {
                SessionsView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }

    private var RPMBar: any View {
        VStack {
            Text("\(viewModel.rpm.safeInt())")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(rpmColor)
                
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

#Preview {
    ContentView()
}
