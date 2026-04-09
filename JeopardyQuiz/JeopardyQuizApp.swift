//
//  JeopardyQuizApp.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//

import SwiftUI
import Combine



@main
struct JeopardyQuizApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
        }
    }
}
