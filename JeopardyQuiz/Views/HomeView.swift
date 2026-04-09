//
//  HomeView.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//


import SwiftUI

struct HomeView: View {
    let onStart: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let theme = AppTheme(themeManager.scheme)
        
        ZStack {
            theme.bgDark.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Titolo JEOPARDY
                Text("JEOPARDY")
                    .font(.custom("AvenirNext-HeavyItalic", size: 80))
                    .foregroundColor(theme.text)
                    .tracking(8)
                    .padding(.top, 80)
                
                Spacer()
                
                // Card centrale
                VStack(spacing: 24) {
                    // Toggle tema in alto a destra
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
                    
                    VStack(spacing: 6) {
                        Text("Quiz a tema anime")
                            .font(.system(size: 15))
                            .foregroundColor(theme.text)
                        Text("Seleziona il numero di giocatori, da 2 a 4")
                            .font(.system(size: 14))
                            .foregroundColor(theme.textMuted)
                    }
                    .multilineTextAlignment(.center)
                    
                    // Pulsante Start
                    Button(action: onStart) {
                        Text("Start")
                            .font(.system(size: 17))
                            .foregroundColor(theme.text)
                            .frame(width: 200, height: 48)
                            .background(theme.bg)
                            .cornerRadius(999)
                            .overlay(
                                RoundedRectangle(cornerRadius: 999)
                                    .stroke(theme.border, lineWidth: 1)
                            )
                    }
                }
                .padding(24)
                .padding(.top, 16)
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
}