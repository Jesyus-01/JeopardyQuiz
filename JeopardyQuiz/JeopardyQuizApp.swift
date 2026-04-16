//
//  JeopardyQuizApp.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//

import SwiftUI
import AVFoundation

@main
struct JeopardyQuizApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    init() {
        // Audio session — forza altoparlante principale
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Audio session error: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
        }
    }
}
