import Foundation
import SwiftData

@Model
final class SessionWeatherSample {
    var id: UUID = UUID()
    @Relationship var session: RaceSession?
    var sessionTime: Double = 0
    var timeLeft: Int32 = 0
    var weatherCode: UInt8 = 0
    var trackTemperature: Int16 = 0
    var airTemperature: Int16 = 0
    var safetyCarStatus: UInt8 = 0
    var createdAt: Date = Date()
    var forecastData: Data?
    
    init(
        session: RaceSession? = nil,
        sessionTime: Double,
        timeLeft: Int32,
        weatherCode: UInt8,
        trackTemperature: Int16,
        airTemperature: Int16,
        safetyCarStatus: UInt8,
        forecast: [WeatherForecastRecord] = []
    ) {
        self.session = session
        self.sessionTime = sessionTime
        self.timeLeft = timeLeft
        self.weatherCode = weatherCode
        self.trackTemperature = trackTemperature
        self.airTemperature = airTemperature
        self.safetyCarStatus = safetyCarStatus
        updateForecast(forecast)
    }
    
    func forecastSamples() -> [WeatherForecastRecord] {
        guard let forecastData else { return [] }
        do {
            return try JSONDecoder().decode([WeatherForecastRecord].self, from: forecastData)
        } catch {
            print("⚠️ Failed to decode forecast samples: \(error)")
            return []
        }
    }
    
    func updateForecast(_ forecast: [WeatherForecastRecord]) {
        guard !forecast.isEmpty else {
            forecastData = nil
            return
        }
        do {
            forecastData = try JSONEncoder().encode(forecast)
        } catch {
            print("⚠️ Failed to encode forecast samples: \(error)")
        }
    }
}

struct WeatherForecastRecord: Codable, Hashable, Identifiable {
    let id: UUID
    let timeOffsetMinutes: Int
    let weatherCode: UInt8
    let trackTemp: Int8
    let airTemp: Int8
    
    init(
        id: UUID = UUID(),
        timeOffsetMinutes: Int,
        weatherCode: UInt8,
        trackTemp: Int8,
        airTemp: Int8
    ) {
        self.id = id
        self.timeOffsetMinutes = timeOffsetMinutes
        self.weatherCode = weatherCode
        self.trackTemp = trackTemp
        self.airTemp = airTemp
    }
}

