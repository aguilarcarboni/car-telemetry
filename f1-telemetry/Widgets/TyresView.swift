import SwiftUI

struct TyresView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            // Header
            HStack {
                Text("TYRES")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                Text(viewModel.tyreCompound)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(tyreCompoundColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(tyreCompoundColor.opacity(0.2))
                    .cornerRadius(4)
                
                Text("\(viewModel.tyreAge) laps")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
            }
            Divider()
                .background(Color.white.opacity(0.2))
            // Four wheels wear & damage
            VStack(spacing: 50) {
                HStack(spacing: 50) {
                    wheelDamageView(wear: viewModel.tyreWearFL)
                    wheelDamageView(wear: viewModel.tyreWearFR)
                }
                HStack(spacing: 50) {
                    wheelDamageView(wear: viewModel.tyreWearRL)
                    wheelDamageView(wear: viewModel.tyreWearRR)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    // MARK: - Subviews
    private func wheelDamageView(wear: Double) -> some View {
        VStack(spacing: 6) {
            ZStack {
                // Outer ring - wear
                Circle()
                    .stroke(damageColor(wear), lineWidth: 6)
                    .frame(width: 50, height: 50)
                
                Text("\(wear.safeInt())%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
    }
    // MARK: - Helpers
    private func damageColor(_ value: Double) -> Color {
        switch value {
        case ..<10: return .green
        case ..<30: return .yellow
        case ..<60: return .orange
        default: return .red
        }
    }

    private var tyreCompoundColor: Color {
        switch viewModel.tyreCompound {
        case "Soft": return .red
        case "Medium": return .yellow
        case "Hard": return .white
        case "Inter": return .green
        case "Wet": return .blue
        default: return .gray
        }
    }
}

// Computed accessors for array data
private extension TelemetryViewModel {
    var tyreWearFL: Double { Double(tyreWear.count > 2 ? tyreWear[2] : 0) }
    var tyreWearFR: Double { Double(tyreWear.count > 3 ? tyreWear[3] : 0) }
    var tyreWearRL: Double { Double(tyreWear.count > 0 ? tyreWear[0] : 0) }
    var tyreWearRR: Double { Double(tyreWear.count > 1 ? tyreWear[1] : 0) }
    var tyreDamageFL: Int { tyreDamage.count > 2 ? Int(tyreDamage[2]) : 0 }
    var tyreDamageFR: Int { tyreDamage.count > 3 ? Int(tyreDamage[3]) : 0 }
    var tyreDamageRL: Int { tyreDamage.count > 0 ? Int(tyreDamage[0]) : 0 }
    var tyreDamageRR: Int { tyreDamage.count > 1 ? Int(tyreDamage[1]) : 0 }
    var brakeDamageFL: Int { brakeDamage.count > 2 ? Int(brakeDamage[2]) : 0 }
    var brakeDamageFR: Int { brakeDamage.count > 3 ? Int(brakeDamage[3]) : 0 }
    var brakeDamageRL: Int { brakeDamage.count > 0 ? Int(brakeDamage[0]) : 0 }
    var brakeDamageRR: Int { brakeDamage.count > 1 ? Int(brakeDamage[1]) : 0 }
}
