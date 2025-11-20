import SwiftUI

struct TelemetryCard<Content: View>: View {
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(20)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.35),
                            accent.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accent.opacity(0.4), lineWidth: 1)
        )
    }
}

struct StatChip: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption2)
                .foregroundStyle(color.opacity(0.7))
            Text(value)
                .font(.system(.body, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

struct ChartPlaceholder: View {
    var message: String = "Waiting for speed data"
    var minHeight: CGFloat = 180
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
            Text(message)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
    }
}

struct TeamThemeMenu: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        Menu {
            ForEach(TeamTheme.allCases) { team in
                Button {
                    themeManager.select(team)
                } label: {
                    HStack {
                        Circle()
                            .fill(team.accent)
                            .frame(width: 10, height: 10)
                        Text(team.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        if themeManager.selectedTeam == team {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "paintpalette.fill")
                Text(themeManager.selectedTeam.displayName)
                    .lineLimit(1)
            }
            .font(.caption.weight(.semibold))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.08), in: Capsule())
            .foregroundStyle(.white)
        }
    }
}

