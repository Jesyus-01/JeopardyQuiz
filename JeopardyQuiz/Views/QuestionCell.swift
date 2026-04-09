//
//  QuestionCell.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//


import SwiftUI

struct QuestionCell: View {
    let question: Question
    let onTap: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let theme = AppTheme(themeManager.scheme)
        
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: AppTheme.cellCornerRadius)
                .fill(theme.bg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cellCornerRadius)
                        .stroke(theme.border, lineWidth: 1)
                )
                .overlay(
                    Group {
                        if !question.isAnswered {
                            Text("\(question.value)")
                                .font(.system(size: 28, weight: .regular))
                                .foregroundColor(theme.text)
                        }
                    }
                )
                .opacity(question.isAnswered ? 0.4 : 1.0)
        }
        .disabled(question.isAnswered)
        .frame(maxWidth: .infinity)
        .frame(height: 110)
    }
}