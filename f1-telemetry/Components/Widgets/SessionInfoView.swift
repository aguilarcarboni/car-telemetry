import SwiftUI

struct SessionInfoView: View {

    @ObservedObject var viewModel: TelemetryViewModel
    
    var body: some View {
        HStack {
            InfoTile(title: "Team", value: teamName)
            InfoTile(title: "Track", value: trackName)
        }
        .frame(maxWidth: .infinity)
    }
    
    private let sessionTypeNames: [UInt8: String] = [
        0: "Unknown",
        1: "Practice",
        2: "Qualifying",
        3: "Race",
        4: "Time Trial"
    ]
    
    private let trackNames: [Int8: String] = [
        -1: "Unknown",
        0: "Melbourne",
        1: "Paul Ricard",
        2: "Shanghai",
        3: "Sakhir",
        4: "Catalunya",
        5: "Monaco",
        6: "Montreal",
        7: "Silverstone",
        8: "Hockenheim",
        9: "Hungaroring",
        10: "Spa",
        11: "Monza",
        12: "Singapore",
        13: "Suzuka",
        14: "Abu Dhabi",
        15: "Texas",
        16: "Brazil",
        17: "Austria",
        18: "Sochi",
        19: "Mexico",
        20: "Baku",
        21: "Sakhir Short",
        22: "Silverstone Short",
        23: "Texas Short",
        24: "Suzuka Short",
        25: "Hanoi",
        26: "Zandvoort",
        27: "Imola",
        28: "Portimão",
        29: "Jeddah",
        30: "Miami",
        31: "Las Vegas",
        32: "Losail"
    ]
    
    private let teamNames: [UInt8: String] = [
        0: "Mercedes",
        1: "Ferrari",
        2: "Red Bull Racing",
        3: "Williams",
        4: "Aston Martin",
        5: "Alpine",
        6: "AlphaTauri",
        7: "Haas",
        8: "McLaren",
        9: "Alfa Romeo"
    ]
    
    private var driverName: String {
        guard viewModel.playerCarIndex < viewModel.participants.count else { return "--" }
        return viewModel.participants[viewModel.playerCarIndex].name
    }
    
    private var teamName: String {
        guard viewModel.playerCarIndex < viewModel.participants.count else { return "--" }
        let teamId = viewModel.participants[viewModel.playerCarIndex].teamId
        return teamNames[teamId] ?? "Team \(teamId)"
    }
    
    private var trackName: String {
        return trackNames[viewModel.trackId] ?? "Track \(viewModel.trackId)"
    }
}
