//
//  RecapView.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 15/04/26.
//

import SwiftUI

struct RecapView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameViewModel: GameViewModel

    @State private var showConfetti: Bool = false

    var body: some View {
        let theme = AppTheme(themeManager.scheme)

        ZStack {
            theme.bgDark.ignoresSafeArea()

            VStack(spacing: 40) {

                // MARK: - Titolo
                VStack(spacing: 8) {
                    Text("Fine partita!")
                        .font(.custom("AvenirNext-HeavyItalic", size: 48))
                        .foregroundColor(theme.text)
                        .tracking(4)

                    if let winner = gameViewModel.winner {
                        Text("Vince \(winner.name)! 🎉")
                            .font(.system(size: 22))
                            .foregroundColor(theme.textMuted)
                    }
                }
                .padding(.top, 60)

                // MARK: - Podio (top 3)
                if gameViewModel.rankedPlayers.count >= 2 {
                    podiumView(theme: theme)
                }

                // MARK: - Classifica completa
                VStack(spacing: 0) {
                    ForEach(gameViewModel.rankedPlayers) { player in
                        playerRow(player: player, theme: theme)

                        if player.id != gameViewModel.rankedPlayers.last?.id {
                            Divider()
                                .background(theme.border)
                                .padding(.horizontal, 24)
                        }
                    }
                }
                .background(theme.bg)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.border, lineWidth: 1)
                )
                .frame(maxWidth: 700)

                // MARK: - Bottoni
                HStack(spacing: 16) {
                    // Gioca di nuovo
                    Button {
                        gameViewModel.resetGame()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Nuova partita")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(theme.text)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(theme.bg)
                        .cornerRadius(999)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(theme.border, lineWidth: 1)
                        )
                    }
                }
                .padding(.bottom, 48)

                Spacer()
            }
            .padding(.horizontal, 24)

            // MARK: - Confetti
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            // Breve ritardo per far vedere la schermata prima del confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showConfetti = true
            }
        }
    }

    // MARK: - Podio

    @ViewBuilder
    private func podiumView(theme: AppTheme) -> some View {
        let ranked = gameViewModel.rankedPlayers
        let first  = ranked[safe: 0]
        let second = ranked[safe: 1]
        let third  = ranked[safe: 2]

        HStack(alignment: .bottom, spacing: 16) {

            // 2° posto
            if let second {
                podiumColumn(player: second, height: 100, label: "2°", theme: theme)
            }

            // 1° posto (più alto)
            if let first {
                podiumColumn(player: first, height: 140, label: "1°", theme: theme)
            }

            // 3° posto (solo se esiste)
            if let third {
                podiumColumn(player: third, height: 70, label: "3°", theme: theme)
            }
        }
        .frame(maxWidth: 500)
    }

    @ViewBuilder
    private func podiumColumn(
        player: Player,
        height: CGFloat,
        label: String,
        theme: AppTheme
    ) -> some View {
        VStack(spacing: 8) {
            // Avatar
            avatarCircle(player: player, size: label == "1°" ? 72 : 56)

            // Nome
            Text(player.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Punteggio
            Text("\(player.score)")
                .font(.system(size: 12))
                .foregroundColor(theme.textMuted)

            // Blocco podio
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(podiumColor(label: label).opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(podiumColor(label: label).opacity(0.4), lineWidth: 1)
                    )
                Text(label)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(podiumColor(label: label))
            }
            .frame(width: 90, height: height)
        }
    }

    private func podiumColor(label: String) -> Color {
        switch label {
        case "1°": return Color(red: 1, green: 0.84, blue: 0)   // oro
        case "2°": return Color(red: 0.75, green: 0.75, blue: 0.75) // argento
        case "3°": return Color(red: 0.8, green: 0.5, blue: 0.2)  // bronzo
        default:   return .gray
        }
    }

    // MARK: - Riga classifica

    @ViewBuilder
    private func playerRow(player: Player, theme: AppTheme) -> some View {
        HStack(spacing: 16) {

            // Posizione
            Text("\(player.rank)°")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.textMuted)
                .frame(width: 32)

            // Avatar
            avatarCircle(player: player, size: 44)

            // Nome + statistiche
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.text)
                HStack(spacing: 12) {
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
                .font(.system(size: 22, weight: .light, design: .monospaced))
                .foregroundColor(player.score < 0 ? .red : theme.text)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Avatar helper

    @ViewBuilder
    private func avatarCircle(player: Player, size: CGFloat) -> some View {
        if let avatar = player.avatar {
            let url = LocalStorageService.shared.localMediaURLSync(for: avatar.filename)
            if let img = UIImage(contentsOfFile: url.path) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                defaultCircle(size: size)
            }
        } else {
            defaultCircle(size: size)
        }
    }

    @ViewBuilder
    private func defaultCircle(size: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color.gray.opacity(0.2))
            Image(systemName: "person.fill")
                .foregroundColor(.gray)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Confetti

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = (0..<80).map { _ in
        ConfettiParticle()
    }

    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { context, size in
                for particle in particles {
                    let x = particle.x * size.width
                    let y = particle.y * size.height
                    let rect = CGRect(x: x, y: y, width: particle.size, height: particle.size)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3)) {
                for i in particles.indices {
                    particles[i].y = 1.2
                    particles[i].x += CGFloat.random(in: -0.2...0.2)
                }
            }
        }
    }
}

struct ConfettiParticle {
    var x: CGFloat = CGFloat.random(in: 0...1)
    var y: CGFloat = CGFloat.random(in: -0.3...0)
    var size: CGFloat = CGFloat.random(in: 6...14)
    var color: Color = [
        .red, .blue, .green, .yellow, .orange, .purple, .pink
    ].randomElement()!
}
