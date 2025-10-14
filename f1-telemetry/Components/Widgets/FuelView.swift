//
//  FuelView.swift
//  f1-telemetry
//
//  Created by Andrés on 10/10/2025.
//

import SwiftUI

struct FuelView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            Text("FUEL")
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
                    Text("\(String(format: "%.1f", viewModel.fuelInTank)) kg")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }

                // Lap Remaining
                HStack {
                    Image(systemName: "timer")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("Laps Remaining")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(String(format: "%.1f", viewModel.fuelRemainingLaps)) laps")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}


