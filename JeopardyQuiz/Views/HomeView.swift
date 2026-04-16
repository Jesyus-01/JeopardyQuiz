//
//  HomeView.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var gameViewModel: GameViewModel
    @ObservedObject var downloadService = DownloadService.shared

    @State private var selectedPlayerCount: Int? = nil
    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        let theme = AppTheme(themeManager.scheme)

        ZStack {
            theme.bgDark.ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Titolo
                Text("JEOPARDY")
                    .font(.custom("AvenirNext-HeavyItalic", size: 80))
                    .foregroundColor(theme.text)
                    .tracking(8)
                    .padding(.top, 80)

                Spacer()

                // MARK: - Card centrale
                VStack(spacing: 24) {

                    // Toggle tema
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Text("Tema")
                                .font(.system(size: 14))
                                .foregroundColor(theme.textMuted)
                            Toggle("", isOn: Binding(
                                get: { themeManager.scheme == .light },
                                set: { _ in themeManager.toggle() }
                            ))
                            .labelsHidden()
                            .tint(theme.primary)
                        }
                    }

                    // Testo info
                    VStack(spacing: 6) {
                        Text("Quiz a tema anime")
                            .font(.system(size: 15))
                            .foregroundColor(theme.text)
                        Text("Seleziona il numero di giocatori, da 2 a 4")
                            .font(.system(size: 14))
                            .foregroundColor(theme.textMuted)
                    }
                    .multilineTextAlignment(.center)

                    // Picker giocatori
                    Menu {
                        Button("2 giocatori") { selectedPlayerCount = 2 }
                        Button("3 giocatori") { selectedPlayerCount = 3 }
                        Button("4 giocatori") { selectedPlayerCount = 4 }
                    } label: {
                        HStack {
                            Text(selectedPlayerCount == nil ? "Scegli..." : "\(selectedPlayerCount!) giocatori")
                                .font(.system(size: 15))
                                .foregroundColor(selectedPlayerCount == nil ? theme.textMuted : theme.text)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13))
                                .foregroundColor(theme.textMuted)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(theme.bgDark)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.border, lineWidth: 1)
                        )
                    }

                    // MARK: - Bottone Start (UNICO)
                    Button {
                        if let count = selectedPlayerCount {
                            gameViewModel.preparePlayerSlots(count: count)
                            gameViewModel.currentScreen = .playerSetup
                        }
                    } label: {
                        Text("Start")
                            .font(.system(size: 17))
                            .foregroundColor(canStart ? theme.text : theme.textMuted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(theme.bg)
                            .cornerRadius(999)
                            .overlay(
                                RoundedRectangle(cornerRadius: 999)
                                    .stroke(theme.border, lineWidth: 1)
                            )
                    }
                    .disabled(!canStart)

                    Divider()
                        .background(theme.border)

                    // MARK: - Sezione Download
                    downloadSection(theme: theme)
                }
                .padding(24)
                .background(theme.bg)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.border, lineWidth: 1)
                )
                .frame(maxWidth: 700)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Sezione download
    @ViewBuilder
    private func downloadSection(theme: AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("📦 Quiz offline")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.text)
                Spacer()
                if let data = downloadService.localData {
                    Text("\(QuizGeneratorService.shared.availableGamesCount(from: data)) partite disponibili")
                        .font(.system(size: 13))
                        .foregroundColor(theme.textMuted)
                }
            }

            statusView(theme: theme)

            HStack(spacing: 12) {
                Button {
                    Task { await downloadService.startDownload() }
                } label: {
                    HStack(spacing: 6) {
                        if isDownloading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: theme.text))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: downloadService.isReadyToPlay ? "arrow.clockwise" : "arrow.down.circle")
                        }
                        Text(downloadService.isReadyToPlay ? "Aggiorna" : "Scarica quiz")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(theme.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(theme.bgDark)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(theme.border, lineWidth: 1)
                    )
                }
                .disabled(isDownloading)

                if downloadService.isReadyToPlay {
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Elimina")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(theme.bgDark)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red.opacity(0.4), lineWidth: 1)
                        )
                    }
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

    // MARK: - Status view
    @ViewBuilder
    private func statusView(theme: AppTheme) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(downloadService.statusMessage)
                .font(.system(size: 13))
                .foregroundColor(theme.textMuted)
            Spacer()
        }
    }

    // MARK: - Computed helpers
    private var canStart: Bool {
        selectedPlayerCount != nil && downloadService.isReadyToPlay
    }

    private var isDownloading: Bool {
        switch downloadService.state {
        case .checkingServer, .checkingUpdates, .downloading, .downloadingMedia:
            return true
        default:
            return false
        }
    }

    private var statusColor: Color {
        switch downloadService.state {
        case .completed, .upToDate:
            return .green
        case .error:
            return .red
        case .idle where downloadService.isReadyToPlay:
            return .green
        default:
            return .orange
        }
    }
}
