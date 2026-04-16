//
//  GameBoardView.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//


import SwiftUI

struct GameBoardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameViewModel: GameViewModel

    var body: some View {
        let theme = AppTheme(themeManager.scheme)

        ZStack {
            theme.bgDark.ignoresSafeArea()

            HStack(spacing: 0) {

                // MARK: - Sidebar giocatori
                VStack(spacing: 12) {
                    ForEach(gameViewModel.players.indices, id: \.self) { index in
                        PlayerPillView(
                            player: gameViewModel.players[index],
                            isActive: index == gameViewModel.activePlayerIndex
                        )
                    }
                    Spacer()
                }
                .frame(width: 200)
                .padding(.top, 24)
                .padding(.leading, 16)

                // MARK: - Tabellone
                GeometryReader { geo in
                    let columnCount = gameViewModel.board.count          // 5 categorie
                    let rowCount    = gameViewModel.board.first?.count ?? 5  // 5 difficulty
                    let spacing: CGFloat = 8
                    let totalHSpacing = spacing * CGFloat(columnCount - 1)
                    let totalVSpacing = spacing * CGFloat(rowCount)      // +1 per header
                    let cellWidth  = (geo.size.width - totalHSpacing) / CGFloat(columnCount)
                    let cellHeight = (geo.size.height - totalVSpacing) / CGFloat(rowCount + 1)

                    VStack(spacing: spacing) {

                        // Header categorie
                        HStack(spacing: spacing) {
                            ForEach(gameViewModel.board, id: \.first?.categoryName) { column in
                                Text(column.first?.categoryName ?? "")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(theme.text)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.7)
                                    .frame(width: cellWidth, height: cellHeight)
                                    .background(theme.bg)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(theme.border, lineWidth: 1)
                                    )
                            }
                        }

                        // Righe valori (difficulty 1→5)
                        ForEach(0..<rowCount, id: \.self) { rowIndex in
                            HStack(spacing: spacing) {
                                ForEach(gameViewModel.board, id: \.first?.categoryName) { column in
                                    if rowIndex < column.count {
                                        let cell = column[rowIndex]
                                        BoardCellView(
                                            cell: cell,
                                            width: cellWidth,
                                            height: cellHeight,
                                            theme: theme
                                        ) {
                                            gameViewModel.selectCell(cell)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }

            // MARK: - Modal domanda
            if gameViewModel.showQuestionModal,
               let cell = gameViewModel.selectedCell {
                QuestionModalView(cell: cell)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: gameViewModel.showQuestionModal)
    }
}

// MARK: - Cella del tabellone

struct BoardCellView: View {
    let cell: BoardCell
    let width: CGFloat
    let height: CGFloat
    let theme: AppTheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(cell.isPlayed ? theme.bg.opacity(0.3) : theme.bg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.border, lineWidth: 1)
                    )

                if !cell.isPlayed {
                    Text("\(cell.points)")
                        .font(.system(size: pointsFontSize(for: width), weight: .light))
                        .foregroundColor(theme.text)
                } else {
                    // Cella già giocata — vuota
                    Rectangle()
                        .fill(Color.clear)
                }
            }
            .frame(width: width, height: height)
        }
        .disabled(cell.isPlayed)
        .buttonStyle(.plain)
    }

    private func pointsFontSize(for width: CGFloat) -> CGFloat {
        width > 140 ? 32 : width > 100 ? 26 : 20
    }
}

// MARK: - Pill giocatore (sidebar)

struct PlayerPillView: View {
    let player: Player
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {

            // Avatar
            avatarImage()
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            // Nome + punteggio
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("\(player.score)")
                    .font(.system(size: 12))
                    .foregroundColor(player.score < 0 ? .red : .white.opacity(0.7))
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(isActive ? 0.12 : 0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isActive ? Color.white.opacity(0.5) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .padding(.trailing, 12)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }

    @ViewBuilder
    private func avatarImage() -> some View {
        if let avatar = player.avatar {
            let assetName = (avatar.filename as NSString).deletingPathExtension
            if let uiImage = UIImage(named: assetName) ?? UIImage(named: avatar.filename) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                defaultAvatar()
            }
        } else {
            defaultAvatar()
        }
    }

    @ViewBuilder
    private func defaultAvatar() -> some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.1))
            Image(systemName: "person.fill")
                .foregroundColor(.white.opacity(0.5))
        }
    }
}
