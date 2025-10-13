//
//  InputsView.swift
//  f1-telemetry
//
//  Created by Andrés on 10/10/2025.
//

import SwiftUI

struct InputsView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Throttle
            VStack(spacing: 6) {
                Text("\(viewModel.throttle.safeInt())%")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                        
                        Rectangle()
                            .fill(Color.green)
                            .frame(height: geometry.size.height * CGFloat(viewModel.throttle / 100))
                    }
                }
                .cornerRadius(4)
                
                Text("Throttle")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            // Brake
            VStack(spacing: 6) {
                Text("\(viewModel.brake.safeInt())%")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.red)
                
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                        
                        Rectangle()
                            .fill(Color.red)
                            .frame(height: geometry.size.height * CGFloat(viewModel.brake / 100))
                    }
                }
                .cornerRadius(4)
                
                Text("Brake")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            // Steering
            VStack(spacing: 6) {
                Text("\((viewModel.steer * 100).safeInt())")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
                
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .cornerRadius(4)
                    
                    GeometryReader { geometry in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 18, height: 18)
                            .position(
                                x: geometry.size.width / 2 + CGFloat(viewModel.steer) * (geometry.size.width / 2 - 9),
                                y: geometry.size.height / 2
                            )
                    }
                }
                
                Text("Steering")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .frame(height: 110)
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}


