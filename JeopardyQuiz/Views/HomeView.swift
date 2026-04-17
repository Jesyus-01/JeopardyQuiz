import SwiftUI

struct HomeView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameViewModel: GameViewModel
    @ObservedObject var downloadService = DownloadService.shared

    @State private var selectedPlayerCount: Int? = nil
    @State private var showDeleteConfirm: Bool  = false
    @State private var animateTitle: Bool        = false

    private let jeopardyGold = Color(red: 0.961, green: 0.773, blue: 0.094)

    var body: some View {
        let theme = AppTheme(themeManager.scheme)
        let isDark = themeManager.scheme == .dark

        ZStack {
            // Sfondo: gradiente blu notte in dark, lavender chiaro in light
            LinearGradient(
                colors: isDark
                    ? [Color(hex: "#0A1220"), Color(hex: "#0D1B2A")]
                    : [Color(hex: "#E8EEF8"), Color(hex: "#D0DCF0")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Toggle tema (angolo in alto a destra)
                HStack {
                    Spacer()
                    themeToggle(theme: theme, isDark: isDark)
                }
                .padding(.top, 20)
                .padding(.trailing, 28)

                // MARK: Titolo
                VStack(spacing: 6) {
                    Text("JEOPARDY")
                        .font(.custom("AvenirNext-HeavyItalic", size: 76))
                        .foregroundColor(isDark ? .white : Color(hex: "#0F2744"))
                        .tracking(8)
                        .shadow(color: jeopardyGold.opacity(isDark ? 0.25 : 0), radius: 20)
                        .scaleEffect(animateTitle ? 1 : 0.88)
                        .opacity(animateTitle ? 1 : 0)

                    Text("Quiz a tema anime")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isDark ? jeopardyGold.opacity(0.8) : Color(hex: "#1A3A5C"))
                        .tracking(2)
                        .opacity(animateTitle ? 1 : 0)
                }
                .padding(.top, 32)
                .padding(.bottom, 48)

                // MARK: Card centrale
                VStack(spacing: 20) {
                    // Selettore giocatori
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Numero di giocatori")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isDark ? jeopardyGold : Color(hex: "#1A3A5C"))
                            .tracking(1)
                            .textCase(.uppercase)

                        playerPicker(theme: theme, isDark: isDark)
                    }

                    // Bottone Start
                    startButton(theme: theme, isDark: isDark)

                    Divider().background(theme.border)

                    // Sezione download
                    downloadSection(theme: theme)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isDark
                              ? Color(hex: "#111827").opacity(0.95)
                              : Color.white.opacity(0.92))
                        .shadow(color: .black.opacity(isDark ? 0.4 : 0.12), radius: 32, y: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isDark ? jeopardyGold.opacity(0.18) : Color(hex: "#1A3A5C").opacity(0.15),
                            lineWidth: 1
                        )
                )
                .frame(maxWidth: 560)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                animateTitle = true
            }
        }
    }

    // MARK: - Toggle tema
    private func themeToggle(theme: AppTheme, isDark: Bool) -> some View {
        Button { themeManager.toggle() } label: {
            HStack(spacing: 6) {
                Image(systemName: isDark ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 13))
                    .foregroundColor(isDark ? jeopardyGold : Color(hex: "#1A3A5C"))
                Text(isDark ? "Dark" : "Light")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isDark ? jeopardyGold : Color(hex: "#1A3A5C"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isDark
                          ? jeopardyGold.opacity(0.1)
                          : Color(hex: "#1A3A5C").opacity(0.08))
                    .overlay(
                        Capsule().stroke(
                            isDark ? jeopardyGold.opacity(0.3) : Color(hex: "#1A3A5C").opacity(0.2),
                            lineWidth: 1
                        )
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isDark)
    }

    // MARK: - Picker giocatori
    private func playerPicker(theme: AppTheme, isDark: Bool) -> some View {
        HStack(spacing: 10) {
            ForEach([2, 3, 4], id: \.self) { count in
                let selected = selectedPlayerCount == count
                Button { selectedPlayerCount = count } label: {
                    Text("\(count)")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(
                            selected
                                ? (isDark ? Color(hex: "#0F2744") : .white)
                                : theme.textMuted
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selected ? jeopardyGold : theme.bgDark)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selected ? jeopardyGold : theme.border,
                                    lineWidth: selected ? 0 : 1
                                )
                        )
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selected)
            }
        }
    }

    // MARK: - Start button
    private func startButton(theme: AppTheme, isDark: Bool) -> some View {
        Button {
            if let count = selectedPlayerCount {
                gameViewModel.preparePlayerSlots(count: count)
                gameViewModel.currentScreen = .playerSetup
            }
        } label: {
            HStack(spacing: 8) {
                if canStart {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                }
                Text("Start")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(canStart
                             ? (isDark ? Color(hex: "#0F2744") : .white)
                             : theme.textMuted)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(canStart ? jeopardyGold : theme.bgDark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(canStart ? Color.clear : theme.border, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: canStart)
        }
        .disabled(!canStart)
        .buttonStyle(.plain)
    }

    // MARK: - Sezione download
    @ViewBuilder
    private func downloadSection(theme: AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Text("📦")
                    Text("Quiz offline")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.text)
                }
                Spacer()
                if let data = downloadService.localData {
                    Text("\(QuizGeneratorService.shared.availableGamesCount(from: data)) partite disponibili")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textMuted)
                }
            }

            // Status
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                Text(downloadService.statusMessage)
                    .font(.system(size: 13))
                    .foregroundColor(theme.textMuted)
                Spacer()
            }

            // Bottoni
            HStack(spacing: 10) {
                Button {
                    Task { await downloadService.startDownload() }
                } label: {
                    HStack(spacing: 6) {
                        if isDownloading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: theme.text))
                                .scaleEffect(0.75)
                        } else {
                            Image(systemName: downloadService.isReadyToPlay ? "arrow.clockwise" : "arrow.down.circle")
                                .font(.system(size: 13))
                        }
                        Text(downloadService.isReadyToPlay ? "Aggiorna" : "Scarica quiz")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(theme.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(theme.bgDark)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(isDownloading)

                if downloadService.isReadyToPlay {
                    Button { showDeleteConfirm = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                            Text("Elimina")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(theme.bgDark)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.35), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog(
                        "Eliminare i dati scaricati?",
                        isPresented: $showDeleteConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Elimina", role: .destructive) {
                            Task { await downloadService.deleteLocalData() }
                        }
                        Button("Annulla", role: .cancel) {}
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private var canStart: Bool {
        selectedPlayerCount != nil && downloadService.isReadyToPlay
    }

    private var isDownloading: Bool {
        switch downloadService.state {
        case .checkingServer, .checkingUpdates, .downloading, .downloadingMedia: return true
        default: return false
        }
    }

    private var statusColor: Color {
        switch downloadService.state {
        case .completed, .upToDate: return .green
        case .error: return .red
        case .idle where downloadService.isReadyToPlay: return .green
        default: return .orange
        }
    }
}

// Hex helper (già definito in GameBoardView — se duplicato rimuovi questa extension)
private extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
