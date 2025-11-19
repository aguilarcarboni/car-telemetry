import SwiftUI
import Combine

enum TeamTheme: String, CaseIterable, Identifiable {
    case neutral
    case redBull
    case ferrari
    case mercedes
    case mclaren
    case astonMartin
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .neutral: return "Neutral"
        case .redBull: return "Oracle Red Bull"
        case .ferrari: return "Scuderia Ferrari"
        case .mercedes: return "Mercedes-AMG"
        case .mclaren: return "McLaren"
        case .astonMartin: return "Aston Martin"
        }
    }
    
    var backgroundGradient: [Color] {
        switch self {
        case .neutral:
            return [
                Color(red: 10 / 255, green: 12 / 255, blue: 20 / 255),
                Color(red: 18 / 255, green: 22 / 255, blue: 32 / 255)
            ]
        case .redBull:
            return [
                Color(red: 5 / 255, green: 4 / 255, blue: 18 / 255),
                Color(red: 9 / 255, green: 8 / 255, blue: 34 / 255),
                Color(red: 34 / 255, green: 11 / 255, blue: 75 / 255)
            ]
        case .ferrari:
            return [
                Color(red: 18 / 255, green: 0 / 255, blue: 0 / 255),
                Color(red: 82 / 255, green: 4 / 255, blue: 4 / 255)
            ]
        case .mercedes:
            return [
                Color(red: 3 / 255, green: 12 / 255, blue: 12 / 255),
                Color(red: 6 / 255, green: 32 / 255, blue: 30 / 255)
            ]
        case .mclaren:
            return [
                Color(red: 22 / 255, green: 10 / 255, blue: 0 / 255),
                Color(red: 70 / 255, green: 35 / 255, blue: 0 / 255)
            ]
        case .astonMartin:
            return [
                Color(red: 2 / 255, green: 18 / 255, blue: 14 / 255),
                Color(red: 7 / 255, green: 54 / 255, blue: 46 / 255)
            ]
        }
    }
    
    var accent: Color {
        switch self {
        case .neutral:
            return Color(red: 0.76, green: 0.80, blue: 0.92)
        case .redBull:
            return Color(red: 0.99, green: 0.72, blue: 0.10)
        case .ferrari:
            return Color(red: 0.94, green: 0.09, blue: 0.13)
        case .mercedes:
            return Color(red: 0.00, green: 0.78, blue: 0.73)
        case .mclaren:
            return Color(red: 1.00, green: 0.53, blue: 0.00)
        case .astonMartin:
            return Color(red: 0.12, green: 0.78, blue: 0.66)
        }
    }
    
    var secondaryAccent: Color {
        switch self {
        case .neutral:
            return Color(red: 0.52, green: 0.57, blue: 0.72)
        case .redBull:
            return Color(red: 0.94, green: 0.28, blue: 0.33)
        case .ferrari:
            return Color(red: 0.99, green: 0.83, blue: 0.25)
        case .mercedes:
            return Color(red: 0.35, green: 0.93, blue: 0.90)
        case .mclaren:
            return Color(red: 0.00, green: 0.65, blue: 0.78)
        case .astonMartin:
            return Color(red: 0.69, green: 0.85, blue: 0.41)
        }
    }
    
    var speedColor: Color {
        switch self {
        case .neutral:
            return Color(red: 0.65, green: 0.74, blue: 0.92)
        case .redBull:
            return Color(red: 0.99, green: 0.78, blue: 0.20)
        case .ferrari:
            return Color(red: 0.97, green: 0.18, blue: 0.16)
        case .mercedes:
            return Color(red: 0.20, green: 0.87, blue: 0.86)
        case .mclaren:
            return Color(red: 1.00, green: 0.61, blue: 0.17)
        case .astonMartin:
            return Color(red: 0.20, green: 0.83, blue: 0.68)
        }
    }
    
    var throttleColor: Color {
        switch self {
        case .neutral:
            return Color(red: 0.52, green: 0.92, blue: 0.75)
        case .redBull:
            return Color(red: 0.29, green: 0.94, blue: 0.64)
        case .ferrari:
            return Color(red: 0.98, green: 0.48, blue: 0.13)
        case .mercedes:
            return Color(red: 0.28, green: 0.92, blue: 0.66)
        case .mclaren:
            return Color(red: 0.99, green: 0.74, blue: 0.31)
        case .astonMartin:
            return Color(red: 0.42, green: 0.92, blue: 0.61)
        }
    }
    
    var brakeColor: Color {
        switch self {
        case .neutral:
            return Color(red: 0.94, green: 0.44, blue: 0.50)
        case .redBull:
            return Color(red: 0.96, green: 0.33, blue: 0.37)
        case .ferrari:
            return Color(red: 0.81, green: 0.12, blue: 0.16)
        case .mercedes:
            return Color(red: 0.86, green: 0.26, blue: 0.38)
        case .mclaren:
            return Color(red: 0.90, green: 0.12, blue: 0.24)
        case .astonMartin:
            return Color(red: 0.95, green: 0.34, blue: 0.30)
        }
    }
    
    var gLatColor: Color {
        switch self {
        case .neutral:
            return Color(red: 0.80, green: 0.84, blue: 0.96)
        case .redBull:
            return Color(red: 1.00, green: 0.64, blue: 0.28)
        case .ferrari:
            return Color(red: 0.99, green: 0.58, blue: 0.18)
        case .mercedes:
            return Color(red: 0.47, green: 0.95, blue: 0.87)
        case .mclaren:
            return Color(red: 0.99, green: 0.68, blue: 0.26)
        case .astonMartin:
            return Color(red: 0.48, green: 0.94, blue: 0.80)
        }
    }
    
    var gLongColor: Color {
        switch self {
        case .neutral:
            return Color(red: 0.55, green: 0.79, blue: 0.98)
        case .redBull:
            return Color(red: 0.31, green: 0.77, blue: 1.00)
        case .ferrari:
            return Color(red: 0.99, green: 0.83, blue: 0.25)
        case .mercedes:
            return Color(red: 0.26, green: 0.67, blue: 0.97)
        case .mclaren:
            return Color(red: 0.00, green: 0.70, blue: 0.90)
        case .astonMartin:
            return Color(red: 0.29, green: 0.79, blue: 0.58)
        }
    }
    
    var verticalGColor: Color {
        switch self {
        case .neutral:
            return Color(red: 0.77, green: 0.66, blue: 0.95)
        case .redBull:
            return Color(red: 0.93, green: 0.52, blue: 0.86)
        case .ferrari:
            return Color(red: 0.98, green: 0.66, blue: 0.73)
        case .mercedes:
            return Color(red: 0.62, green: 0.85, blue: 0.99)
        case .mclaren:
            return Color(red: 0.99, green: 0.84, blue: 0.64)
        case .astonMartin:
            return Color(red: 0.76, green: 0.96, blue: 0.83)
        }
    }
    
    var powerGaugeGradient: [Color] {
        switch self {
        case .neutral:
            return [
                Color(red: 0.34, green: 0.62, blue: 0.94),
                Color(red: 0.68, green: 0.78, blue: 1.00)
            ]
        case .redBull:
            return [
                Color(red: 0.12, green: 0.62, blue: 0.87),
                Color(red: 0.96, green: 0.31, blue: 0.34)
            ]
        case .ferrari:
            return [
                Color(red: 0.99, green: 0.82, blue: 0.01),
                Color(red: 0.69, green: 0.00, blue: 0.00)
            ]
        case .mercedes:
            return [
                Color(red: 0.00, green: 0.82, blue: 0.73),
                Color(red: 0.17, green: 0.95, blue: 0.92)
            ]
        case .mclaren:
            return [
                Color(red: 1.00, green: 0.76, blue: 0.30),
                Color(red: 1.00, green: 0.45, blue: 0.05)
            ]
        case .astonMartin:
            return [
                Color(red: 0.20, green: 0.74, blue: 0.64),
                Color(red: 0.62, green: 0.84, blue: 0.32)
            ]
        }
    }
}

final class ThemeManager: ObservableObject {
    @Published private(set) var selectedTeam: TeamTheme {
        didSet {
            defaults.set(selectedTeam.rawValue, forKey: Self.storageKey)
        }
    }
    
    private static let storageKey = "selectedTeam"
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if
            let storedValue = defaults.string(forKey: Self.storageKey),
            let storedTheme = TeamTheme(rawValue: storedValue)
        {
            selectedTeam = storedTheme
        } else {
            selectedTeam = .neutral
        }
    }
    
    func select(_ theme: TeamTheme) {
        guard selectedTeam != theme else { return }
        selectedTeam = theme
    }
}

