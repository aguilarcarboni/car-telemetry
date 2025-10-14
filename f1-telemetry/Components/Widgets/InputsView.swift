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
            .frame(maxWidth: .infinity, maxHeight: 110)
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)

            // Brake
            VStack(spacing: 6) {

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
            .frame(maxWidth: .infinity, maxHeight: 110)
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)

        }
    }
}


