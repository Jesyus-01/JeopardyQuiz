//
//  ContentView.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//


import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var isGameStarted = false
    
    var body: some View {
        let theme = AppTheme(themeManager.scheme)
        
        ZStack {
            theme.bgDark.ignoresSafeArea()
            
            if isGameStarted {
                GameBoardView(viewModel: viewModel)
                    .transition(.opacity)
            } else {
                HomeView(onStart: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isGameStarted = true
                    }
                })
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isGameStarted)
    }
}