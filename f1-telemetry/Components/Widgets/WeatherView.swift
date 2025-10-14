import SwiftUI

struct WeatherView: View {
    @ObservedObject var viewModel: TelemetryViewModel

    private let weatherIconMap: [(icon: String, color: Color)] = [
        ("sun.max.fill", .yellow),          // Clear
        ("cloud.sun.fill", .orange),        // Light Cloud
        ("cloud.fill", .gray),              // Overcast
        ("cloud.rain.fill", .blue),         // Light Rain
        ("cloud.heavyrain.fill", .blue),    // Heavy Rain
        ("cloud.bolt.rain.fill", .purple)  // Storm
    ]
    
    var body: some View {
        HStack {
            InfoTile(title: "Weather Forecast", content: AnyView(WeatherForecast))
        }
        
    }

    var WeatherForecast: some View {
        HStack(spacing: 12) {
            ForEach(0..<min(viewModel.weatherForecastNext.count, 5), id: \.self) { idx in
                let sample = viewModel.weatherForecastNext[idx]
                let wCode = sample.weather
                let icon = wCode < weatherIconMap.count ? weatherIconMap[Int(wCode)].icon : "questionmark"
                let color = wCode < weatherIconMap.count ? weatherIconMap[Int(wCode)].color : .blue
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title)
                    Text("+\(sample.timeOffset)′")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
    }
}
