//
//  Theme.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//

import SwiftUI
import Combine

// MARK: - Theme Environment Key
enum AppColorScheme {
    case dark, light
}

class ThemeManager: ObservableObject {
    @Published var scheme: AppColorScheme = .dark
    
    func toggle() {
        scheme = scheme == .dark ? .light : .dark
    }
}

// MARK: - Colors
struct AppTheme {
    let scheme: AppColorScheme
    
    init(_ scheme: AppColorScheme = .dark) {
        self.scheme = scheme
    }
    
    var bgDark: Color {
        scheme == .dark
            ? Color(red: 0.08, green: 0.09, blue: 0.13)
            : Color(red: 0.90, green: 0.91, blue: 0.94)
    }
    var bg: Color {
        scheme == .dark
            ? Color(red: 0.12, green: 0.13, blue: 0.18)
            : Color(red: 0.94, green: 0.95, blue: 0.98)
    }
    var bgLight: Color {
        scheme == .dark
            ? Color(red: 0.16, green: 0.18, blue: 0.23)
            : Color(red: 1.0, green: 1.0, blue: 1.0)
    }
    var text: Color {
        scheme == .dark
            ? Color(red: 0.96, green: 0.95, blue: 0.98)
            : Color(red: 0.10, green: 0.10, blue: 0.15)
    }
    var textMuted: Color {
        scheme == .dark
            ? Color(red: 0.76, green: 0.75, blue: 0.82)
            : Color(red: 0.38, green: 0.37, blue: 0.45)
    }
    var border: Color {
        scheme == .dark
            ? Color(red: 0.40, green: 0.39, blue: 0.48).opacity(0.6)
            : Color(red: 0.55, green: 0.54, blue: 0.62).opacity(0.6)
    }
    var borderMuted: Color {
        scheme == .dark
            ? Color(red: 0.30, green: 0.29, blue: 0.38).opacity(0.5)
            : Color(red: 0.65, green: 0.64, blue: 0.72).opacity(0.5)
    }
    var primary: Color {
        scheme == .dark
            ? Color(red: 0.60, green: 0.62, blue: 0.90)
            : Color(red: 0.25, green: 0.27, blue: 0.65)
    }
    var success: Color {
        scheme == .dark
            ? Color(red: 0.40, green: 0.80, blue: 0.55)
            : Color(red: 0.15, green: 0.60, blue: 0.35)
    }
    var danger: Color {
        scheme == .dark
            ? Color(red: 0.85, green: 0.45, blue: 0.35)
            : Color(red: 0.70, green: 0.20, blue: 0.15)
    }
    
    // MARK: - Constants
    static let cellCornerRadius: CGFloat = 14
    static let dialogCornerRadius: CGFloat = 18
}
