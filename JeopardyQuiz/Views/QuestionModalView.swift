//
//  QuestionModalView.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 15/04/26.
//

import SwiftUI
import AVFoundation

struct QuestionModalView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameViewModel: GameViewModel

    let cell: BoardCell

    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var isPlaying: Bool = false
    @State private var mediaURL: URL? = nil

    var body: some View {
        let theme = AppTheme(themeManager.scheme)

        ZStack {
            // Sfondo scurito
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    gameViewModel.closeWithoutScore()
                }

            // Card modale
            VStack(spacing: 0) {

                // MARK: - Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cell.categoryName)
                            .font(.system(size: 13))
                            .foregroundColor(theme.textMuted)
                        Text("\(cell.points) punti")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.text)
                    }
                    Spacer()
                    // Turno di chi
                    if let player = gameViewModel.players[safe: gameViewModel.activePlayerIndex] {
                        HStack(spacing: 8) {
                            if let avatar = player.avatar {
                                let url = LocalStorageService.shared.localMediaURLSync(for: avatar.filename)
                                if let img = UIImage(contentsOfFile: url.path) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                }
                            }
                            Text(player.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.text)
                        }
                    }

                    // Chiudi
                    Button {
                        stopAudio()
                        gameViewModel.closeWithoutScore()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(theme.textMuted)
                            .padding(8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

                Divider().background(theme.border)

                // MARK: - Corpo domanda
                ScrollView {
                    VStack(spacing: 24) {
                        questionBody(theme: theme)
                    }
                    .padding(24)
                }

                Divider().background(theme.border)

                // MARK: - Footer azioni
                footerActions(theme: theme)
                    .padding(24)
            }
            .background(theme.bg)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(theme.border, lineWidth: 1)
            )
            .frame(maxWidth: 680)
            .padding(.horizontal, 40)
            .shadow(color: .black.opacity(0.3), radius: 24, y: 8)
        }
        .task {
            // Precarica URL media al mount del modal
            if let media = gameViewModel.media(for: cell.question) {
                mediaURL = await gameViewModel.localMediaURL(for: media.filename)
            }
        }
        .onDisappear {
            stopAudio()
        }
    }

    // MARK: - Corpo domanda (switch per tipo)

    @ViewBuilder
    private func questionBody(theme: AppTheme) -> some View {
        switch cell.question.questionType {

        case .open:
            openQuestion(theme: theme)

        case .multipleChoice:
            multipleChoiceQuestion(theme: theme)

        case .image:
            imageQuestion(theme: theme)

        case .audio:
            audioQuestion(theme: theme)
        }
    }

    // MARK: - Open

    @ViewBuilder
    private func openQuestion(theme: AppTheme) -> some View {
        VStack(spacing: 20) {
            Text(cell.question.text)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(theme.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if gameViewModel.answerVisible {
                answerCard(
                    text: cell.question.correctOpenAnswer ?? "—",
                    theme: theme
                )
            }
        }
    }

    // MARK: - Multiple Choice

    @ViewBuilder
    private func multipleChoiceQuestion(theme: AppTheme) -> some View {
        let options = gameViewModel.options(for: cell.question)

        VStack(spacing: 20) {
            Text(cell.question.text)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(theme.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Griglia 2x2
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

    @ViewBuilder
    private func optionButton(option: ChoiceOption, theme: AppTheme) -> some View {
        let isSelected = gameViewModel.selectedOptionId == option.optionId
        let showResult = gameViewModel.answerVisible
        let isCorrect  = option.isCorrect

        let bgColor: Color = {
            if showResult {
                if isCorrect { return Color.green.opacity(0.2) }
                if isSelected && !isCorrect { return Color.red.opacity(0.2) }
            } else if isSelected {
                return theme.primary.opacity(0.15)
            }
            return theme.bgDark
        }()

        let borderColor: Color = {
            if showResult {
                if isCorrect { return .green }
                if isSelected && !isCorrect { return .red }
            } else if isSelected {
                return theme.primary
            }
            return theme.border
        }()

        Button {
            guard !gameViewModel.answerVisible else { return }
            gameViewModel.selectedOptionId = option.optionId
        } label: {
            HStack(spacing: 12) {
                // Lettera opzione A/B/C/D
                Text(optionLabel(order: option.optionOrder))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.textMuted)
                    .frame(width: 24)

                Text(option.optionText)
                    .font(.system(size: 15))
                    .foregroundColor(theme.text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if showResult && isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                if showResult && isSelected && !isCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding(14)
            .background(bgColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: gameViewModel.answerVisible)
    }

    // MARK: - Image

    @ViewBuilder
    private func imageQuestion(theme: AppTheme) -> some View {
        VStack(spacing: 20) {
            if let url = mediaURL,
               let uiImage = UIImage(contentsOfFile: url.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.bgDark)
                    .frame(height: 200)
                    .overlay(
                        ProgressView()
                    )
            }

            Text(cell.question.text)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(theme.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if gameViewModel.answerVisible {
                answerCard(
                    text: cell.question.correctOpenAnswer ?? "—",
                    theme: theme
                )
            }
        }
    }

    // MARK: - Audio

    @ViewBuilder
    private func audioQuestion(theme: AppTheme) -> some View {
        VStack(spacing: 24) {

            // Player audio
            VStack(spacing: 16) {
                Image(systemName: "music.note")
                    .font(.system(size: 48))
                    .foregroundColor(theme.textMuted)

                Button {
                    toggleAudio()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 28))
                        Text(isPlaying ? "Pausa" : "Riproduci")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(theme.text)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.bgDark)
                    .cornerRadius(999)
                    .overlay(
                        RoundedRectangle(cornerRadius: 999)
                            .stroke(theme.border, lineWidth: 1)
                    )
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(theme.bgDark)
            .cornerRadius(16)

            Text(cell.question.text)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(theme.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if gameViewModel.answerVisible {
                answerCard(
                    text: cell.question.correctOpenAnswer ?? "—",
                    theme: theme
                )
            }
        }
    }

    // MARK: - Answer card

    @ViewBuilder
    private func answerCard(text: String, theme: AppTheme) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
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

            // Mostra risposta
            if !gameViewModel.answerVisible {
                Button {
                    withAnimation { gameViewModel.answerVisible = true }
                } label: {
                    Text("Mostra risposta")
                        .font(.system(size: 15))
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
            }

            Spacer()

            // Sbagliato
            Button {
                stopAudio()
                gameViewModel.markWrong()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                    Text("Sbagliato")
                }
                .font(.system(size: 15))
                .foregroundColor(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.08))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }

            // Corretto
            Button {
                stopAudio()
                gameViewModel.markCorrect()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                    Text("Corretto")
                }
                .font(.system(size: 15))
                .foregroundColor(.green)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.08))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Audio helpers

    private func toggleAudio() {
        guard let url = mediaURL else { return }
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
        } else {
            if audioPlayer == nil {
                audioPlayer = try? AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
            }
            audioPlayer?.play()
            isPlaying = true
        }
    }

    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }

    // MARK: - Helpers

    private func optionLabel(order: Int) -> String {
        ["A", "B", "C", "D"][safe: order - 1] ?? "\(order)"
    }
}

// MARK: - Safe subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
