//
//  PlayerPillView.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//


import SwiftUI

struct PlayerPillView: View {
    let name: String
    let score: Int
    let isActive: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let theme = AppTheme(themeManager.scheme)
        
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 44, height: 44)
                .foregroundColor(theme.textMuted)
                .clipShape(Circle())
                .overlay(Circle().stroke(theme.border, lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(theme.text)
                Text("\(score)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.textMuted)
            }
        }
        .padding(10)
        .background(theme.bg)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isActive ? theme.primary.opacity(0.75) : theme.borderMuted,
                        lineWidth: isActive ? 2 : 1)
        )
        .shadow(color: isActive ? theme.primary.opacity(0.35) : .clear, radius: 10)
    }
}
