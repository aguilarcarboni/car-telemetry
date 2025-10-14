import SwiftUI

/// Renders a very simple top-down track map using the player car world coordinates.
/// Only the player car is shown for now. As more packet data is available we could
/// add other cars as well.
struct MapView: View {
    @ObservedObject var viewModel: TelemetryViewModel

    /// Keeps recent points for drawing the trace (in view coordinates)
    @State private var tracePoints: [CGPoint] = []

    /// Maximum number of points to keep in the trace to avoid memory bloat
    private let maxTracePoints: Int = 1500

    var body: some View {
        GeometryReader { geo in
            // Fixed scale: metres per point (adjust if too zoomed or too far)
            let metresPerPoint = 3.0
            let scale = 1.0 / metresPerPoint // points per metre

            // Center of the view acts as world origin (0,0)
            let centerX = geo.size.width / 2.0
            let centerY = geo.size.height / 2.0

            // Convert world coordinates -> view space
            let x = centerX + viewModel.worldX * scale
            // In F1 the Z axis increases forward. Convert to canvas Y with origin top-left (flip sign)
            let y = centerY - viewModel.worldZ * scale

            ZStack {
                // Dark track background
                Rectangle()
                    .fill(Color.black)

                // Trace path
                Path { path in
                    guard tracePoints.count > 1 else { return }
                    path.addLines(tracePoints)
                }
                .stroke(Color.green.opacity(0.8), lineWidth: 1)

                // Player car
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .position(x: x, y: y)
            }
            .onChange(of: viewModel.worldX) { _ in
                // Append new point whenever the X coordinate changes (proxy for movement)
                let newPoint = CGPoint(x: x, y: y)
                tracePoints.append(newPoint)
                if tracePoints.count > maxTracePoints {
                    tracePoints.removeFirst(tracePoints.count - maxTracePoints)
                }
            }
            .animation(.linear(duration: 0.1), value: viewModel.worldX)
        }
    }
}
