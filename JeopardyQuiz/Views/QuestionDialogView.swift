//
//  QuestionDialogView.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//


import SwiftUI

struct QuestionDialogView: View {
    let question: Question
    let onCorrect: () -> Void
    let onWrong: () -> Void
    let onClose: () -> Void
    
    @State private var isAnswerRevealed = false
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let theme = AppTheme(themeManager.scheme)
        
        ZStack {
            // Backdrop
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { onClose() }
            
            // Dialog
            VStack(spacing: 0) {
                
                // Header
                HStack {
                    Text("\(question.category) - \(question.value)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.text)
                    Spacer()
                    Button(action: onClose) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme.bgLight.opacity(0.55))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(theme.borderMuted.opacity(0.7), lineWidth: 1)
                                )
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(theme.text)
                        }
                        .frame(width: 36, height: 36)
                    }
                }
                .padding(18)
                
                Divider().background(theme.borderMuted)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(question.question)
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(theme.text)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 10)
                        
                        // Mostra risposta button
                        if !isAnswerRevealed {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isAnswerRevealed = true
                                }
                            }) {
                                Text("Mostra risposta")
                                    .font(.system(size: 15))
                                    .foregroundColor(theme.text)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(theme.bgLight.opacity(0.55))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(theme.borderMuted.opacity(0.7), lineWidth: 1)
                                    )
                            }
                        }
                        
                        // Risposta rivelata
                        if isAnswerRevealed {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Risposta:")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(theme.textMuted)
                                Text(question.answer)
                                    .font(.system(size: 16))
                                    .foregroundColor(theme.text)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(theme.success.opacity(0.14))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.success.opacity(0.55), lineWidth: 1)
                            )
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
                
                Divider().background(theme.borderMuted)
                
                // Footer actions
                HStack(spacing: 10) {
                    Spacer()
                    
                    // Errata
                    Button(action: { onWrong() }) {
                        Text("Errata")
                            .font(.system(size: 14))
                            .foregroundColor(theme.text)
                            .frame(height: 40)
                            .padding(.horizontal, 14)
                            .background(theme.bgLight.opacity(0.55))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.borderMuted.opacity(0.7), lineWidth: 1)
                            )
                    }
                    
                    // Corretta
                    Button(action: { onCorrect() }) {
                        Text("Corretta")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.text)
                            .frame(height: 40)
                            .padding(.horizontal, 14)
                            .background(theme.primary.opacity(0.22))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.primary.opacity(0.7), lineWidth: 1)
                            )
                    }
                    
                    // Chiudi
                    Button(action: { onClose() }) {
                        Text("Chiudi")
                            .font(.system(size: 14))
                            .foregroundColor(theme.text)
                            .frame(height: 40)
                            .padding(.horizontal, 14)
                            .background(theme.bg.opacity(0.35))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.borderMuted.opacity(0.7), lineWidth: 1)
                            )
                    }
                }
                .padding(18)
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.dialogCornerRadius)
                    .fill(theme.bg.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.dialogCornerRadius)
                            .stroke(theme.border.opacity(0.55), lineWidth: 1)
                    )
            )
            .frame(width: min(UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.screen.bounds.width ?? 400 - 24, 980))
            .frame(maxHeight: min(UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.screen.bounds.height ?? 800 * 0.76, 740))
        }
    }
}
