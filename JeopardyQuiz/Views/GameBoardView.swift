//
//  GameBoardView.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//


import SwiftUI

struct GameBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let theme = AppTheme(themeManager.scheme)
        
        ZStack {
            // Sfondo
            theme.bgDark.ignoresSafeArea()
            
            HStack(spacing: 12) {
                
                // Colonna giocatori a sinistra
                VStack(spacing: 12) {
                    PlayerPillView(name: "Giocatore 1", score: viewModel.score, isActive: true)
                    Spacer()
                }
                .frame(width: 180)
                
                // Griglia categorie
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.categories) { category in
                            CategoryColumnView(category: category) { question in
                                viewModel.selectQuestion(question)
                            }
                            .frame(width: 160)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(24)
            .padding(.top, 8)
            
            // Dialog domanda
            if case .questionSelected(let question) = viewModel.gameState {
                QuestionDialogView(
                    question: question,
                    onCorrect: { viewModel.markCorrect(question) },
                    onWrong: { viewModel.markWrong(question) },
                    onClose: { viewModel.gameState = .idle }
                )
                .transition(.opacity)
                .zIndex(10)
            }
            
            if case .showingAnswer(let question) = viewModel.gameState {
                QuestionDialogView(
                    question: question,
                    onCorrect: { viewModel.markCorrect(question) },
                    onWrong: { viewModel.markWrong(question) },
                    onClose: { viewModel.gameState = .idle }
                )
                .transition(.opacity)
                .zIndex(10)
            }
            
            // Loading
            if viewModel.isLoading {
                ZStack {
                    theme.bgDark.opacity(0.8).ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.text))
                        .scaleEffect(1.5)
                }
            }
            
            // Errore
            if let error = viewModel.errorMessage {
                ZStack {
                    theme.bgDark.opacity(0.9).ignoresSafeArea()
                    VStack(spacing: 16) {
                        Text("Errore di connessione")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(theme.text)
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(theme.textMuted)
                        Button("Riprova") {
                            viewModel.loadGame()
                        }
                        .foregroundColor(theme.text)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(theme.bg)
                        .cornerRadius(999)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(theme.border, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadGame()
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.gameState == .idle)
    }
}
