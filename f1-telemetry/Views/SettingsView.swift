import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        GeometryReader { proxy in
            let layout = SettingsLayout(size: proxy.size)
            let theme = themeManager.selectedTeam
            
            ZStack {
                LinearGradient(
                    colors: theme.backgroundGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                        
                        TeamThemeMenu()
                            .padding(.top, 4)
                        
                        if layout.usesWideLayout {
                            HStack(alignment: .top, spacing: layout.cardSpacing) {
                                connectionCard
                            }
                        } else {
                            VStack(spacing: layout.cardSpacing) {
                                connectionCard
                            }
                        }
                    }
                    .padding(.horizontal, layout.horizontalPadding)
                    .padding(.vertical, layout.verticalPadding)
                }
            }
        }
    }
    
    // MARK: - Sections
    private var connectionCard: some View {
        TelemetryCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("Connection Status", systemImage: "dot.radiowaves.left.and.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                
                HStack(spacing: 12) {
                    statusIndicator
                    VStack(alignment: .leading, spacing: 4) {
                        Text(connectionStatusLabel)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("IP: \(ipLabel)")
                    }
                    Spacer()
                }
                
                Divider().background(Color.white.opacity(0.08))
                
                HStack(spacing: 12) {
                    Button(action: toggleConnection) {
                        Label(
                            viewModel.isConnected ? "Stop Listener" : "Start Listener",
                            systemImage: viewModel.isConnected ? "pause.fill" : "play.fill"
                        )
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.isConnected
                            ? themeManager.selectedTeam.brakeColor.opacity(0.85)
                            : themeManager.selectedTeam.throttleColor.opacity(0.9),
                            in: Capsule()
                        )
                        .foregroundStyle(.white)
                    }
                    
                    Button(action: viewModel.resetHistories) {
                        Label("Reset Charts", systemImage: "arrow.counterclockwise")
                            .font(.callout.weight(.semibold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.08), in: Capsule())
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    
                    Spacer()
                }
            }
        }
    }

    // MARK: - Helpers
    
    private var connectionStatusLabel: String {
        viewModel.isConnected ? "Connected" : "Waiting for connection"
    }
    
    private var ipLabel: String {
        "\(viewModel.localIPAddress):\(viewModel.port)"
    }
    
    private var shortSessionUID: String {
        guard viewModel.sessionUID.count > 6 else { return viewModel.sessionUID }
        return "#" + viewModel.sessionUID.suffix(6)
    }
    
    private var positionLabel: String {
        viewModel.position > 0 ? "P\(viewModel.position)" : "--"
    }
    
    private var gForceMagnitude: String {
        let magnitude = hypot(viewModel.gLat, viewModel.gLong)
        return String(format: "%.2f g", magnitude)
    }
    
    private var lastPacketDescription: String {
        guard viewModel.packetsReceived > 0 else { return "Awaiting first packet" }
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: viewModel.lastUpdateTime, relativeTo: Date())
    }
    
    private var statusIndicator: some View {
        Capsule()
            .fill(viewModel.isConnected ? Color.green : Color.red)
            .frame(width: 12, height: 12)
            .shadow(color: (viewModel.isConnected ? Color.green : Color.red).opacity(0.6), radius: 6)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
    
    private func toggleConnection() {
        if viewModel.isConnected {
            viewModel.stopListening()
        } else {
            viewModel.startListening()
        }
    }
}

// MARK: - Layout

private struct SettingsLayout {
    let size: CGSize
    let usesWideLayout: Bool
    let sectionSpacing: CGFloat
    let cardSpacing: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    
    init(size: CGSize) {
        self.size = size
        self.usesWideLayout = size.width >= 820
        self.sectionSpacing = usesWideLayout ? 32 : 24
        self.cardSpacing = usesWideLayout ? 24 : 18
        self.horizontalPadding = max(20, size.width * 0.05)
        self.verticalPadding = max(24, size.height * 0.04)
    }
}

#Preview {
    SettingsView(viewModel: TelemetryViewModel())
        .environmentObject(ThemeManager())
}

