// QuestionModalView.swift — UI rewrite
// Miglioramenti:
//   1. Sfondo modale con identità visiva Jeopardy (bordo oro, header colorato)
//   2. Header: categoria in oro uppercase, punti grandi e bold
//   3. Risposte multiple: tap state animato, layout più leggibile
//   4. Bottoni Sbagliato/Corretto: più incisivi, fill solido con icona
//   5. "Mostra risposta": stile neutro ma visibile
//   6. Audio player: stile coerente con il resto

import SwiftUI
import AVFoundation

struct QuestionModalView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameViewModel: GameViewModel
    let cell: BoardCell

    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var isPlaying: Bool = false
    @State private var mediaURL: URL? = nil
    @State private var currentTime: Double = 0
    @State private var duration: Double = 1
    @State private var timer: Timer? = nil

    // Oro Jeopardy — usato per accent nella modale
    private let jeopardyGold = Color(red: 0.961, green: 0.773, blue: 0.094)

    var body: some View {
        let theme = AppTheme(themeManager.scheme)

        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { gameViewModel.closeWithoutScore() }

            VStack(spacing: 0) {
                headerView(theme: theme)
                Divider().background(jeopardyGold.opacity(0.3))

                ScrollView {
                    VStack(spacing: 24) {
                        questionBody(theme: theme)
                    }
                    .padding(24)
                }

                Divider().background(theme.border)
                footerActions(theme: theme)
                    .padding(24)
            }
            .background(theme.bg)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(jeopardyGold.opacity(0.35), lineWidth: 1.5)
            )
            .frame(maxWidth: 680)
            .padding(.horizontal, 40)
            .shadow(color: .black.opacity(0.4), radius: 32, y: 12)
        }
        .task {
            if let media = gameViewModel.media(for: cell.question) {
                mediaURL = await gameViewModel.localMediaURL(for: cell.question)
                if let url = mediaURL, media.mediaType == "AUDIO" {
                    audioPlayer = try? AVAudioPlayer(contentsOf: url)
                    audioPlayer?.prepareToPlay()
                    duration = audioPlayer?.duration ?? 1
                }
            }
        }
        .onDisappear { stopAudio() }
    }

    // MARK: - Header
    private func headerView(theme: AppTheme) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(cell.categoryName.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(jeopardyGold)

                Text("\(cell.points) punti")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(theme.text)
            }

            Spacer()

            // Avatar + nome giocatore attivo
            if !gameViewModel.players.isEmpty {
                let player = gameViewModel.players[gameViewModel.activePlayerIndex]
                HStack(spacing: 8) {
                    if let avatar = player.avatar {
                        let assetName = (avatar.filename as NSString).deletingPathExtension
                        if let img = UIImage(named: assetName) ?? UIImage(named: avatar.filename) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 34, height: 34)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(jeopardyGold.opacity(0.6), lineWidth: 1.5))
                        }
                    }
                    Text(player.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.text)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(jeopardyGold.opacity(0.08))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(jeopardyGold.opacity(0.25), lineWidth: 1)
                )
            }

            Button {
                stopAudio()
                gameViewModel.closeWithoutScore()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textMuted)
                    .frame(width: 32, height: 32)
                    .background(theme.bgDark)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(theme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Corpo domanda
    @ViewBuilder
    private func questionBody(theme: AppTheme) -> some View {
        let media = gameViewModel.media(for: cell.question)

        switch cell.question.questionType {
        case .open, .image:
            VStack(spacing: 20) {
                mediaContent(media: media, theme: theme)

                questionText(theme: theme)

                if gameViewModel.answerVisible {
                    answerCard(text: cell.question.correctOpenAnswer ?? "—", theme: theme)
                }
            }

        case .multipleChoice, .audio:
            VStack(spacing: 20) {
                mediaContent(media: media, theme: theme)
                multipleChoiceContent(theme: theme)
            }
        }
    }

    // MARK: - Media (immagine o audio)
    @ViewBuilder
    private func mediaContent(media: QuestionMedia?, theme: AppTheme) -> some View {
        if let media = media {
            if media.mediaType == "IMAGE" {
                if let url = mediaURL, let uiImage = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                } else if mediaURL == nil {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.bgDark)
                        .frame(height: 200)
                        .overlay(ProgressView())
                }
            } else if media.mediaType == "AUDIO" {
                audioPlayerView(theme: theme)
            }
        }
    }

    // MARK: - Testo domanda
    private func questionText(theme: AppTheme) -> some View {
        Text(cell.question.text)
            .font(.system(size: 22, weight: .medium))
            .foregroundColor(theme.text)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Multiple choice
    @ViewBuilder
    private func multipleChoiceContent(theme: AppTheme) -> some View {
        let options = gameViewModel.options(for: cell.question)

        VStack(spacing: 20) {
            questionText(theme: theme)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                ForEach(options) { option in
                    optionButton(option: option, theme: theme)
                }
            }
        }
    }

    // MARK: - Audio player
    @ViewBuilder
    private func audioPlayerView(theme: AppTheme) -> some View {
        VStack(spacing: 16) {
            Image(systemName: isPlaying ? "music.note.list" : "music.note")
                .font(.system(size: 36))
                .foregroundColor(jeopardyGold)
                .animation(.easeInOut(duration: 0.2), value: isPlaying)

            Button { toggleAudio() } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(jeopardyGold)
            }
            .buttonStyle(.plain)

            VStack(spacing: 6) {
                Slider(
                    value: $currentTime,
                    in: 0...max(duration, 1),
                    onEditingChanged: { editing in
                        if !editing { audioPlayer?.currentTime = currentTime }
                    }
                )
                .tint(jeopardyGold)

                HStack {
                    Text(formatTime(currentTime))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(theme.textMuted)
                    Spacer()
                    Text(formatTime(duration))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(theme.textMuted)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(theme.bgDark)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(jeopardyGold.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Option button
    @ViewBuilder
    private func optionButton(option: ChoiceOption, theme: AppTheme) -> some View {
        let isSelected  = gameViewModel.selectedOptionId == option.optionId
        let showResult  = gameViewModel.answerVisible
        let isCorrect   = option.isCorrect

        let bgColor: Color = {
            if showResult {
                return isCorrect ? Color.green.opacity(0.15) :
                       (isSelected ? Color.red.opacity(0.15) : theme.bgDark)
            }
            return isSelected ? jeopardyGold.opacity(0.12) : theme.bgDark
        }()

        let borderColor: Color = {
            if showResult {
                return isCorrect ? .green : (isSelected ? .red : theme.border)
            }
            return isSelected ? jeopardyGold : theme.border
        }()

        Button {
            guard !gameViewModel.answerVisible else { return }
            gameViewModel.selectedOptionId = option.optionId
        } label: {
            HStack(spacing: 12) {
                Text(optionLabel(order: option.optionOrder))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isSelected ? jeopardyGold : theme.textMuted)
                    .frame(width: 24, height: 24)
                    .background(isSelected ? jeopardyGold.opacity(0.15) : theme.bgDark.opacity(0))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(isSelected ? jeopardyGold.opacity(0.5) : theme.border, lineWidth: 1))

                Text(option.optionText)
                    .font(.system(size: 15))
                    .foregroundColor(theme.text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if showResult && isCorrect {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                } else if showResult && isSelected && !isCorrect {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(bgColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: gameViewModel.answerVisible)
        .animation(.easeInOut(duration: 0.12), value: isSelected)
    }

    // MARK: - Answer card
    @ViewBuilder
    private func answerCard(text: String, theme: AppTheme) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 18))
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.text)
            Spacer()
        }
        .padding(16)
        .background(Color.green.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.easeOut(duration: 0.2), value: gameViewModel.answerVisible)
    }

    // MARK: - Footer azioni
    @ViewBuilder
    private func footerActions(theme: AppTheme) -> some View {
        HStack(spacing: 12) {
            if !gameViewModel.answerVisible {
                Button {
                    withAnimation { gameViewModel.answerVisible = true }
                } label: {
                    Text("Mostra risposta")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.textMuted)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(theme.bgDark)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(theme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Sbagliato
            Button {
                stopAudio()
                gameViewModel.markWrong()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                    Text("Sbagliato")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.75))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            // Corretto
            Button {
                stopAudio()
                gameViewModel.markCorrect()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                    Text("Corretto")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.75))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Audio helpers
    private func toggleAudio() {
        guard let url = mediaURL else { return }
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
            stopTimer()
        } else {
            if audioPlayer == nil {
                audioPlayer = try? AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
                duration = audioPlayer?.duration ?? 1
            }
            audioPlayer?.play()
            isPlaying = true
            startTimer()
        }
    }

    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        stopTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let player = audioPlayer else { return }
            currentTime = player.currentTime
            if !player.isPlaying {
                isPlaying = false
                currentTime = 0
                stopTimer()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ time: Double) -> String {
        let t = max(0, Int(time))
        return String(format: "%d:%02d", t / 60, t % 60)
    }

    private func optionLabel(order: Int) -> String {
        (order >= 1 && order <= 4) ? ["A", "B", "C", "D"][order - 1] : "\(order)"
    }
}

