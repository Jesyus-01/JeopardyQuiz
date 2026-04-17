import SwiftUI

// MARK: - Token colori adattativi
struct BoardColors {
    let bg:           Color
    let sidebar:      Color
    let header:       Color
    let headerText:   Color
    let cell:         Color
    let cellText:     Color
    let cellGlow:     Color
    let cellPlayed:   Color
    let cellBorder:   Color
    let pillActive:   Color
    let pillActiveBg: Color
    let pillBorder:   Color
    let divider:      Color

    static let dark = BoardColors(
        bg:            Color(hex: "#0D1B2A"),
        sidebar:       Color(hex: "#0A1526"),
        header:        Color(hex: "#1A3A5C"),
        headerText:    Color(hex: "#F5C518"),
        cell:          Color(hex: "#0F2744"),
        cellText:      Color(hex: "#F5C518"),
        cellGlow:      Color(hex: "#F5C518").opacity(0.35),
        cellPlayed:    Color(hex: "#0A1521"),
        cellBorder:    Color.white.opacity(0.07),
        pillActive:    Color(hex: "#F5C518"),
        pillActiveBg:  Color(hex: "#F5C518").opacity(0.12),
        pillBorder:    Color(hex: "#F5C518").opacity(0.45),
        divider:       Color.white.opacity(0.06)
    )

    static let light = BoardColors(
        bg:            Color(hex: "#1A3A5C"),
        sidebar:       Color(hex: "#132D47"),
        header:        Color(hex: "#0F2744"),
        headerText:    Color(hex: "#F5C518"),
        cell:          Color(hex: "#E8F0F8"),
        cellText:      Color(hex: "#0F2744"),
        cellGlow:      Color.clear,
        cellPlayed:    Color(hex: "#B8C9D9"),
        cellBorder:    Color(hex: "#0F2744").opacity(0.12),
        pillActive:    Color(hex: "#F5C518"),
        pillActiveBg:  Color(hex: "#F5C518").opacity(0.18),
        pillBorder:    Color(hex: "#F5C518").opacity(0.6),
        divider:       Color.white.opacity(0.08)
    )
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

// MARK: - GameBoardView
struct GameBoardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameViewModel: GameViewModel

    private var colors: BoardColors {
        themeManager.scheme == .dark ? .dark : .light
    }

    var body: some View {
        ZStack {
            colors.bg.ignoresSafeArea()

            HStack(spacing: 0) {
                sidebarView
                    .frame(width: 220)

                Rectangle()
                    .fill(colors.divider)
                    .frame(width: 1)

                GeometryReader { geo in
                    boardGrid(geo: geo)
                }
                .padding(12)
            }
        }
        .sheet(isPresented: $gameViewModel.showQuestionModal) {
            if let cell = gameViewModel.selectedCell {
                QuestionModalView(cell: cell)
                    .environmentObject(themeManager)
                    .environmentObject(gameViewModel)
            }
        }
    }

    // MARK: Sidebar
    private var sidebarView: some View {
        VStack(spacing: 10) {
            Spacer()
            ForEach(gameViewModel.players.indices, id: \.self) { index in
                PlayerPillView(
                    player: gameViewModel.players[index],
                    isActive: index == gameViewModel.activePlayerIndex,
                    colors: colors
                )
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .background(colors.sidebar)
    }

    // MARK: Griglia
    private func boardGrid(geo: GeometryProxy) -> some View {
        let columnCount = gameViewModel.board.count
        let rowCount    = gameViewModel.board.first?.count ?? 5
        let spacing: CGFloat = 8
        let cellWidth  = (geo.size.width  - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
        let cellHeight = (geo.size.height - spacing * CGFloat(rowCount)) / CGFloat(rowCount + 1)

        return VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                ForEach(gameViewModel.board, id: \.first?.categoryName) { column in
                    CategoryHeaderCell(
                        name: column.first?.categoryName ?? "",
                        width: cellWidth,
                        height: cellHeight,
                        colors: colors
                    )
                }
            }

            ForEach(0..<rowCount, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(gameViewModel.board, id: \.first?.categoryName) { column in
                        if row < column.count {
                            BoardCellButton(
                                cell: column[row],
                                width: cellWidth,
                                height: cellHeight,
                                colors: colors,
                                onTap: { gameViewModel.selectCell(column[row]) }
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - CategoryHeaderCell
private struct CategoryHeaderCell: View {
    let name:   String
    let width:  CGFloat
    let height: CGFloat
    let colors: BoardColors

    var body: some View {
        Text(name.uppercased())
            .font(.system(size: fontSize, weight: .bold))
            .tracking(1.2)
            .foregroundColor(colors.headerText)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.6)
            .frame(width: width, height: height)
            .background(colors.header)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(colors.headerText.opacity(0.2), lineWidth: 1)
            )
    }

    private var fontSize: CGFloat {
        width > 140 ? 14 : width > 100 ? 12 : 10
    }
}

// MARK: - BoardCellButton
private struct BoardCellButton: View {
    let cell:   BoardCell
    let width:  CGFloat
    let height: CGFloat
    let colors: BoardColors
    let onTap:  () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(cell.isPlayed ? colors.cellPlayed : colors.cell)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(colors.cellBorder, lineWidth: 1)
                    )

                if cell.isPlayed {
                    Image(systemName: "checkmark")
                        .font(.system(size: checkmarkSize, weight: .semibold))
                        .foregroundColor(colors.cellText.opacity(0.4))
                } else {
                    Text("\(cell.points)")
                        .font(.system(size: pointsSize, weight: .bold))
                        .foregroundColor(colors.cellText)
                        .shadow(color: colors.cellGlow, radius: 6)
                }
            }
            .frame(width: width, height: height)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .disabled(cell.isPlayed)
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !cell.isPlayed { isPressed = true } }
                .onEnded   { _ in isPressed = false }
        )
    }

    private var pointsSize:    CGFloat { width > 140 ? 34 : width > 100 ? 28 : 22 }
    private var checkmarkSize: CGFloat { width > 140 ? 22 : width > 100 ? 18 : 14 }
}

// MARK: - PlayerPillView
struct PlayerPillView: View {
    let player:   Player
    let isActive: Bool
    let colors:   BoardColors

    var body: some View {
        HStack(spacing: 10) {
            avatarView
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(
                        isActive ? colors.pillActive : Color.white.opacity(0.2),
                        lineWidth: isActive ? 2 : 1
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isActive ? colors.pillActive : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("\(player.score)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(
                        player.score < 0
                            ? .red
                            : (isActive ? colors.pillActive : .white.opacity(0.85))
                    )
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: player.score)
            }

            Spacer()

            if isActive {
                Image(systemName: "chevron.right.circle.fill")
                    .foregroundColor(colors.pillActive.opacity(0.7))
                    .font(.system(size: 14))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isActive ? colors.pillActiveBg : Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isActive ? colors.pillBorder : Color.white.opacity(0.07),
                            lineWidth: isActive ? 1.5 : 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let avatar = player.avatar {
            let name = (avatar.filename as NSString).deletingPathExtension
            if let img = UIImage(named: name) ?? UIImage(named: avatar.filename) {
                Image(uiImage: img).resizable().scaledToFill()
            } else { placeholder }
        } else { placeholder }
    }

    private var placeholder: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.08))
            Image(systemName: "person.fill").foregroundColor(.white.opacity(0.4))
        }
    }
}
