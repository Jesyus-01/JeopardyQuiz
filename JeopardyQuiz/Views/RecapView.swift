import SwiftUI

struct RecapView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameViewModel: GameViewModel
    @State private var animateIn    = false

    private let jeopardyGold = Color(red: 0.961, green: 0.773, blue: 0.094)

    var body: some View {
        let theme = AppTheme(themeManager.scheme)
        let ranked = gameViewModel.rankedPlayers

        ZStack {
            theme.bgDark.ignoresSafeArea()

            VStack(spacing: 0) {
                // Titolo
                titleSection(theme: theme)
                    .padding(.top, 48)
                    .padding(.bottom, 32)

                // Podio
                if ranked.count >= 2 {
                    podiumView(ranked: ranked, theme: theme)
                        .padding(.bottom, 32)
                        .scaleEffect(animateIn ? 1 : 0.85)
                        .opacity(animateIn ? 1 : 0)
                }

                // Classifica
                leaderboardView(ranked: ranked, theme: theme)
                    .frame(maxWidth: 680)
                    .padding(.horizontal, 24)
                    .offset(y: animateIn ? 0 : 40)
                    .opacity(animateIn ? 1 : 0)

                Spacer(minLength: 24)

                // CTA
                Button { gameViewModel.resetGame() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Nuova partita")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(theme.text)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(theme.bg)
                    .cornerRadius(999)
                    .overlay(RoundedRectangle(cornerRadius: 999).stroke(theme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 48)
            }

        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.15)) {
                animateIn = true
            }
        }
    }

    // MARK: - Titolo
    private func titleSection(theme: AppTheme) -> some View {
        VStack(spacing: 10) {
            Text("Fine partita!")
                .font(.custom("AvenirNext-HeavyItalic", size: 48))
                .foregroundColor(theme.text)

            if let winner = gameViewModel.winner {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(jeopardyGold)
                    Text("Vince \(winner.name)!")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(jeopardyGold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(jeopardyGold.opacity(0.1))
                .cornerRadius(999)
                .overlay(RoundedRectangle(cornerRadius: 999).stroke(jeopardyGold.opacity(0.3), lineWidth: 1))
            }
        }
    }

    // MARK: - Podio
    private func podiumView(ranked: [Player], theme: AppTheme) -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            // 2° posto — sinistra
            if ranked.count > 1 {
                podiumColumn(player: ranked[1], position: 2, barHeight: 90, theme: theme)
            }
            // 1° posto — centro (più alto)
            podiumColumn(player: ranked[0], position: 1, barHeight: 130, theme: theme)
            // 3° posto — destra
            if ranked.count > 2 {
                podiumColumn(player: ranked[2], position: 3, barHeight: 65, theme: theme)
            }
        }
        .frame(maxWidth: 460)
    }

    private func podiumColumn(player: Player, position: Int, barHeight: CGFloat, theme: AppTheme) -> some View {
        let color = podiumColor(position: position)
        let isFirst = position == 1

        return VStack(spacing: 6) {
            // Avatar
            avatarCircle(player: player, size: isFirst ? 68 : 52, borderColor: color)

            // Nome
            Text(player.name)
                .font(.system(size: isFirst ? 14 : 12, weight: .semibold))
                .foregroundColor(theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Punteggio
            Text("\(player.score)")
                .font(.system(size: isFirst ? 16 : 13, weight: .bold))
                .foregroundColor(color)

            // Blocco podio
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color.opacity(0.5), lineWidth: isFirst ? 1.5 : 1)
                    )
                Text("\(position)°")
                    .font(.system(size: isFirst ? 24 : 18, weight: .bold))
                    .foregroundColor(color)
            }
            .frame(width: isFirst ? 100 : 82, height: barHeight)
        }
    }

    private func podiumColor(position: Int) -> Color {
        switch position {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)    // oro
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)   // argento
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)   // bronzo
        default: return .gray
        }
    }

    // MARK: - Classifica
    private func leaderboardView(ranked: [Player], theme: AppTheme) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(ranked.enumerated()), id: \.element.id) { index, player in
                playerRow(player: player, position: index + 1, theme: theme)
                if index < ranked.count - 1 {
                    Divider()
                        .background(theme.border)
                        .padding(.horizontal, 24)
                }
            }
        }
        .background(theme.bg)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.border, lineWidth: 1))
    }

    private func playerRow(player: Player, position: Int, theme: AppTheme) -> some View {
        HStack(spacing: 14) {
            // Posizione
            Text("\(position)°")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(position == 1 ? jeopardyGold : theme.textMuted)
                .frame(width: 28)

            // Avatar
            avatarCircle(
                player: player,
                size: 42,
                borderColor: position == 1 ? jeopardyGold : theme.border
            )

            // Nome + stats
            VStack(alignment: .leading, spacing: 3) {
                Text(player.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.text)

                HStack(spacing: 10) {
                    Label("\(player.correctAnswers) corrette", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    Label("\(player.wrongAnswers) sbagliate", systemImage: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }

            Spacer()

            // Punteggio
            Text("\(player.score)")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(player.score < 0 ? .red : (position == 1 ? jeopardyGold : theme.text))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(position == 1 ? jeopardyGold.opacity(0.05) : Color.clear)
    }

    // MARK: - Avatar helper
    @ViewBuilder
    private func avatarCircle(player: Player, size: CGFloat, borderColor: Color) -> some View {
        Group {
            if let avatar = player.avatar {
                let assetName = (avatar.filename as NSString).deletingPathExtension
                if let img = UIImage(named: assetName) ?? UIImage(named: avatar.filename) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholderCircle()
                }
            } else {
                placeholderCircle()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(borderColor, lineWidth: 1.5))
    }

    @ViewBuilder
    private func placeholderCircle() -> some View {
        ZStack {
            Circle().fill(Color.gray.opacity(0.2))
            Image(systemName: "person.fill").foregroundColor(.gray)
        }
    }
}
