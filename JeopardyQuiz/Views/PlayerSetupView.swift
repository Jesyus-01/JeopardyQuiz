import SwiftUI

struct PlayerSetupView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameViewModel: GameViewModel
    @ObservedObject var downloadService = DownloadService.shared

    private let jeopardyGold = Color(red: 0.961, green: 0.773, blue: 0.094)

    var body: some View {
        let theme   = AppTheme(themeManager.scheme)
        let isDark  = themeManager.scheme == .dark

        ZStack {
            LinearGradient(
                colors: isDark
                    ? [Color(hex: "#0A1220"), Color(hex: "#0D1B2A")]
                    : [Color(hex: "#E8EEF8"), Color(hex: "#D0DCF0")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Chi gioca?")
                        .font(.custom("AvenirNext-HeavyItalic", size: 42))
                        .foregroundColor(isDark ? .white : Color(hex: "#0F2744"))
                        .tracking(4)

                    Text("\(gameViewModel.players.count) giocatori")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(isDark ? jeopardyGold.opacity(0.8) : Color(hex: "#1A3A5C"))
                        .textCase(.uppercase)
                }
                .padding(.top, 48)
                .padding(.bottom, 40)

                // Cards giocatori
                HStack(spacing: 16) {
                    ForEach(gameViewModel.players.indices, id: \.self) { index in
                        PlayerCardView(
                            player: $gameViewModel.players[index],
                            playerNumber: index + 1,
                            availableAvatars: filteredAvatars,
                            usedAvatarIds: usedAvatarIds(excluding: index),
                            usedNames: usedNames(excluding: index),
                            theme: theme,
                            isDark: isDark,
                            gold: jeopardyGold
                        )
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Bottone Start game
                Button {
                    guard let data = downloadService.localData else { return }
                    gameViewModel.setupGame(players: gameViewModel.players, data: data)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        Text("Start game")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(canStart ? (isDark ? Color(hex: "#0F2744") : .white) : theme.textMuted)
                    .frame(width: 240, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 999)
                            .fill(canStart ? jeopardyGold : theme.bgDark)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 999)
                            .stroke(canStart ? Color.clear : theme.border, lineWidth: 1)
                    )
                    .animation(.easeInOut(duration: 0.2), value: canStart)
                }
                .disabled(!canStart)
                .buttonStyle(.plain)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Helpers
    private var filteredAvatars: [Avatar] {
        (downloadService.localData?.avatars ?? [])
            .filter { $0.filename != "avatar-default.jpg" }
            .sorted { $0.avatarId < $1.avatarId }
    }

    private var canStart: Bool {
        let allHaveAvatar  = gameViewModel.players.allSatisfy { $0.hasSelectedAvatar }
        let allHaveName    = gameViewModel.players.allSatisfy { $0.hasName }
        let names          = gameViewModel.players.map { $0.name.trimmingCharacters(in: .whitespaces).lowercased() }
        let avatars        = gameViewModel.players.compactMap { $0.avatar?.avatarId }
        let uniqueNames    = Set(names).count == gameViewModel.players.count
        let uniqueAvatars  = Set(avatars).count == gameViewModel.players.count
        return allHaveAvatar && allHaveName && uniqueNames && uniqueAvatars
    }

    private func usedAvatarIds(excluding index: Int) -> Set<String> {
        Set(gameViewModel.players.indices
            .filter { $0 != index }
            .compactMap { gameViewModel.players[$0].avatar?.avatarId })
    }

    private func usedNames(excluding index: Int) -> Set<String> {
        Set(gameViewModel.players.indices
            .filter { $0 != index }
            .map { gameViewModel.players[$0].name.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty })
    }
}

// MARK: - PlayerCardView
struct PlayerCardView: View {
    @Binding var player: Player
    let playerNumber:    Int
    let availableAvatars: [Avatar]
    let usedAvatarIds:   Set<String>
    let usedNames:       Set<String>
    let theme:           AppTheme
    let isDark:          Bool
    let gold:            Color

    @State private var avatarIndex: Int = 0

    private var isDuplicateName: Bool {
        let t = player.name.trimmingCharacters(in: .whitespaces).lowercased()
        return !t.isEmpty && usedNames.contains(t)
    }

    var body: some View {
        VStack(spacing: 24) {

            // Numero giocatore badge
            Text("Giocatore \(playerNumber)")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(isDark ? gold.opacity(0.8) : Color(hex: "#1A3A5C"))
                .textCase(.uppercase)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(isDark ? gold.opacity(0.1) : Color(hex: "#1A3A5C").opacity(0.08))
                .cornerRadius(999)
                .overlay(
                    Capsule().stroke(
                        isDark ? gold.opacity(0.3) : Color(hex: "#1A3A5C").opacity(0.2),
                        lineWidth: 1
                    )
                )

            // Avatar carousel
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    Button { prevAvatar() } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(isDark ? gold.opacity(0.6) : Color(hex: "#1A3A5C").opacity(0.5))
                    }
                    .buttonStyle(.plain)

                    avatarView()
                        .frame(width: 96, height: 96)

                    Button { nextAvatar() } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(isDark ? gold.opacity(0.6) : Color(hex: "#1A3A5C").opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }

                // Indicatore posizione avatar
                if !availableAvatars.isEmpty {
                    Text(avatarIndex == 0 ? "Scegli avatar" : "\(avatarIndex) / \(availableAvatars.count)")
                        .font(.system(size: 11))
                        .foregroundColor(theme.textMuted)
                }
            }

            // Campo nome
            VStack(spacing: 6) {
                TextField("Giocatore \(playerNumber)", text: $player.name)
                    .font(.system(size: 16))
                    .foregroundColor(theme.text)
                    .multilineTextAlignment(.center)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 4)

                Rectangle()
                    .fill(isDuplicateName ? Color.red : (isDark ? gold.opacity(0.4) : Color(hex: "#1A3A5C").opacity(0.3)))
                    .frame(height: 1.5)
                    .animation(.easeInOut(duration: 0.15), value: isDuplicateName)

                if isDuplicateName {
                    Text("Nome già in uso")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isDark
                      ? Color(hex: "#111827").opacity(0.9)
                      : Color.white.opacity(0.88))
                .shadow(color: .black.opacity(isDark ? 0.35 : 0.1), radius: 20, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isDark ? gold.opacity(0.18) : Color(hex: "#1A3A5C").opacity(0.15),
                    lineWidth: 1
                )
        )
        .frame(minWidth: 200, maxWidth: 260)
    }

    // MARK: - Avatar view
    @ViewBuilder
    private func avatarView() -> some View {
        let borderColor = avatarIndex > 0
            ? (isDark ? gold : Color(hex: "#1A3A5C"))
            : theme.border

        Group {
            if avatarIndex == 0 {
                ZStack {
                    Circle().fill(isDark ? Color.white.opacity(0.05) : Color(hex: "#1A3A5C").opacity(0.05))
                    Image(systemName: "person.fill")
                        .font(.system(size: 38))
                        .foregroundColor(theme.textMuted)
                }
            } else {
                let avatar = availableAvatars[avatarIndex - 1]
                let assetName = (avatar.filename as NSString).deletingPathExtension
                if let img = UIImage(named: assetName) ?? UIImage(named: avatar.filename) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Circle().fill(theme.bgDark)
                        Image(systemName: "person.fill")
                            .font(.system(size: 38))
                            .foregroundColor(theme.textMuted)
                    }
                }
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
        .overlay(Circle().stroke(borderColor, lineWidth: avatarIndex > 0 ? 2.5 : 1.5))
        .animation(.easeInOut(duration: 0.15), value: avatarIndex)
    }

    // MARK: - Navigazione
    private func nextAvatar() {
        guard !availableAvatars.isEmpty else { return }
        var next = avatarIndex
        repeat { next = (next % availableAvatars.count) + 1 }
        while usedAvatarIds.contains(availableAvatars[next - 1].avatarId) && next != avatarIndex
        avatarIndex = next
        player.avatar = availableAvatars[avatarIndex - 1]
    }

    private func prevAvatar() {
        guard !availableAvatars.isEmpty else { return }
        var prev = avatarIndex
        repeat { prev = prev <= 1 ? availableAvatars.count : prev - 1 }
        while usedAvatarIds.contains(availableAvatars[prev - 1].avatarId) && prev != avatarIndex
        avatarIndex = prev
        player.avatar = availableAvatars[avatarIndex - 1]
    }
}

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
