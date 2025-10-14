import SwiftUI

struct ParticipantsView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    
    var body: some View {
        let count = min(viewModel.activeCars, viewModel.participants.count)
        List(0..<count, id: \.self) { index in
            let p = viewModel.participants[index]
            HStack {
                Text("#\(p.raceNumber)").bold().frame(width:40, alignment: .leading)
                VStack(alignment: .leading) {
                    Text(p.name)
                    Text(teamName(p.teamId)).font(.caption).foregroundColor(.gray)
                }
                Spacer()
                if p.aiControlled { Text("AI").foregroundColor(.orange) }
            }
        }
    }
    private func teamName(_ id: UInt8) -> String { // minimal mapping
        switch id {
        case 0: return "Mercedes"
        case 1: return "Ferrari"
        case 2: return "Red Bull"
        default: return "Team \(id)"
        }
    }
}

#Preview { ParticipantsView(viewModel: TelemetryViewModel()) }
