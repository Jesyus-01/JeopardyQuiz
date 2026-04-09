//
//  CategoryColumnView.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//


import SwiftUI

struct CategoryColumnView: View {
    let category: Category
    let onSelectQuestion: (Question) -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let theme = AppTheme(themeManager.scheme)
        
        VStack(spacing: 10) {
            // Header categoria
            RoundedRectangle(cornerRadius: AppTheme.cellCornerRadius)
                .fill(theme.bg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cellCornerRadius)
                        .stroke(theme.border, lineWidth: 1)
                )
                .overlay(
                    Text(category.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.text)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 76)
            
            // Celle domande
            ForEach(category.questions) { question in
                QuestionCell(question: question) {
                    onSelectQuestion(question)
                }
            }
        }
    }
}