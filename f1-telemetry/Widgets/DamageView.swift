import SwiftUI

struct DamageView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    
    private struct DamageItem: Identifiable {
        let id = UUID()
        let label: String
        let value: Int
    }
    
    private var items: [DamageItem] {
        [
            DamageItem(label: "Front Wing", value: viewModel.frontWingDamage),
            DamageItem(label: "Rear Wing", value: viewModel.rearWingDamage),
            DamageItem(label: "Floor", value: viewModel.floorDamage),
            DamageItem(label: "Diffuser", value: viewModel.diffuserDamage),
            DamageItem(label: "Sidepods", value: viewModel.sidepodDamage),
            DamageItem(label: "Gearbox", value: viewModel.gearBoxDamage),
            DamageItem(label: "Engine", value: viewModel.engineDamagePercent)
        ]
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("DAMAGE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            Divider()
                .background(Color.white.opacity(0.2))
            ForEach(items) { item in
                damageRow(label: item.label, value: item.value)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func damageRow(label: String, value: Int) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
            Spacer()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                    Rectangle()
                        .fill(damageColor(Double(value)))
                        .frame(width: geo.size.width * CGFloat(min(Double(value)/100.0,1.0)))
                }
            }
            .frame(height: 6)
            .cornerRadius(3)
            Text("\(value)%")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
    
    private func damageColor(_ val: Double) -> Color {
        switch val {
        case ..<10: return .green
        case ..<30: return .yellow
        case ..<60: return .orange
        default: return .red
        }
    }
}
