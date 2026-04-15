//
//  PlayerSetupView.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 15/04/26.
//

import SwiftUI

struct PlayerSetupView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameViewModel: GameViewModel
    @ObservedObject var downloadService = DownloadService.shared

    var body: some View {
        let theme = AppTheme(themeManager.scheme)

        ZStack {
            theme.bgDark.ignoresSafeArea()

            VStack(spacing: 32) {

                // MARK: - Header
                Text("Chi gioca?")
                    .font(.custom("AvenirNext-HeavyItalic", size: 36))
                    .foregroundColor(theme.text)
                    .tracking(4)
                    .padding(.top, 48)

                // MARK: - Card giocatori
                HStack(spacing: 20) {
                    ForEach(gameViewModel.players.indices, id: \.self) { index in
                        PlayerCardView(
                            player: $gameViewModel.players[index],
                            playerNumber: index + 1,
                            availableAvatars: downloadService.localData?.avatars ?? [],
                            usedAvatarIds: usedAvatarIds(excluding: index),
                            usedNames: usedNames(excluding: index),
                            theme: theme
                        )
                    }
                }
                .padding(.horizontal, 24)

                // MARK: - Bottone Start game
                Button {
                    guard let data = downloadService.localData else { return }
                    gameViewModel.setupGame(
                        players: gameViewModel.players,
                        data: data
                    )
                } label: {
                    Text("Start game")
                        .font(.system(size: 17))
                        .foregroundColor(canStart ? theme.text : theme.textMuted)
                        .frame(width: 200, height: 48)
                        .background(theme.bg)
                        .cornerRadius(999)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(
                                    canStart ? theme.border : theme.border.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                }
                .disabled(!canStart)

                Spacer()
            }
        }
    }

    // MARK: - Validazione

    private var canStart: Bool {
        let allHaveAvatar = gameViewModel.players.allSatisfy { $0.hasSelectedAvatar }
        let allHaveName   = gameViewModel.players.allSatisfy { $0.hasName }
        let names  = gameViewModel.players.map { $0.name.trimmingCharacters(in: .whitespaces).lowercased() }
        let avatars = gameViewModel.players.compactMap { $0.avatar?.avatarId }
        let uniqueNames   = Set(names).count == gameViewModel.players.count
        let uniqueAvatars = Set(avatars).count == gameViewModel.players.count
        return allHaveAvatar && allHaveName && uniqueNames && uniqueAvatars
    }

    private func usedAvatarIds(excluding index: Int) -> Set<Int> {
        Set(
            gameViewModel.players
                .indices
                .filter { $0 != index }
                .compactMap { gameViewModel.players[$0].avatar?.avatarId }
        )
    }

    private func usedNames(excluding index: Int) -> Set<String> {
        Set(
            gameViewModel.players
                .indices
                .filter { $0 != index }
                .map { gameViewModel.players[$0].name.trimmingCharacters(in: .whitespaces).lowercased() }
                .filter { !$0.isEmpty }
        )
    }
}

// MARK: - Card singolo giocatore

struct PlayerCardView: View {
    @Binding var player: Player
    let playerNumber: Int
    let availableAvatars: [Avatar]
    let usedAvatarIds: Set<Int>
    let usedNames: Set<String>
    let theme: AppTheme

    // Indice corrente nell'array avatar (0 = nessuno scelto)
    @State private var avatarIndex: Int = 0

    private var isDuplicateName: Bool {
        let trimmed = player.name.trimmingCharacters(in: .whitespaces).lowercased()
        return !trimmed.isEmpty && usedNames.contains(trimmed)
    }

    var body: some View {
        VStack(spacing: 20) {

            // MARK: - Avatar carousel
            HStack(spacing: 16) {

                // Freccia sinistra
                Button {
                    prevAvatar()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(theme.textMuted)
                }

                // Avatar corrente
                avatarView()
                    .frame(width: 100, height: 100)

                // Freccia destra
                Button {
                    nextAvatar()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(theme.textMuted)
                }
            }

            // MARK: - Campo nome
            VStack(spacing: 4) {
                TextField("Giocatore \(playerNumber)", text: $player.name)
                    .font(.system(size: 15))
                    .foregroundColor(theme.text)
                    .multilineTextAlignment(.center)
                    .autocorrectionDisabled()

                Rectangle()
                    .fill(isDuplicateName ? Color.red : theme.border)
                    .frame(height: 1)

                if isDuplicateName {
                    Text("Nome già in uso")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(24)
        .background(theme.bg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.border, lineWidth: 1)
        )
        .frame(minWidth: 200, maxWidth: 260)
    }

    // MARK: - Avatar view

    @ViewBuilder
    private func avatarView() -> some View {
        if avatarIndex == 0 {
            // Nessun avatar scelto — placeholder
            ZStack {
                Circle()
                    .fill(theme.bgDark)
                    .overlay(Circle().stroke(theme.border, lineWidth: 2))
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(theme.textMuted)
            }
        } else {
            let avatar = availableAvatars[avatarIndex - 1]
            let localURL = LocalStorageService.shared.localMediaURLSync(for: avatar.filename)
            // Carica immagine da file locale
            if let uiImage = UIImage(contentsOfFile: localURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(theme.border, lineWidth: 2))
            } else {
                // Fallback se file non trovato
                ZStack {
                    Circle()
                        .fill(theme.bgDark)
                        .overlay(Circle().stroke(theme.border, lineWidth: 2))
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(theme.textMuted)
                }
            }
        }
    }

    // MARK: - Navigazione avatar

    private func nextAvatar() {
        guard !availableAvatars.isEmpty else { return }
        var next = avatarIndex
        repeat {
            next = (next % availableAvatars.count) + 1
        } while usedAvatarIds.contains(availableAvatars[next - 1].avatarId) && next != avatarIndex
        avatarIndex = next
        player.avatar = availableAvatars[avatarIndex - 1]
    }

    private func prevAvatar() {
        guard !availableAvatars.isEmpty else { return }
        var prev = avatarIndex
        repeat {
            prev = prev <= 1 ? availableAvatars.count : prev - 1
        } while usedAvatarIds.contains(availableAvatars[prev - 1].avatarId) && prev != avatarIndex
        avatarIndex = prev
        player.avatar = availableAvatars[avatarIndex - 1]
    }
}
