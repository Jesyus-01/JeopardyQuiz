//
//  GameViewModel.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//


import Foundation
import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var gameState: GameState = .idle
    @Published var score: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func loadGame() {
        isLoading = true
        errorMessage = nil
        
        QuizService.shared.fetchQuestions(amount: 25) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let questions):
                    self?.buildCategories(from: questions)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func buildCategories(from questions: [Question]) {
        let grouped = Dictionary(grouping: questions, by: { $0.category })
        categories = grouped.prefix(5).enumerated().map { index, pair in
            let sortedQuestions = pair.value.prefix(5).enumerated().map { qIndex, q in
                Question(id: q.id, category: q.category, question: q.question,
                         answer: q.answer, value: (qIndex + 1) * 200)
            }
            return Category(id: index, title: pair.key, questions: Array(sortedQuestions))
        }
    }
    
    func selectQuestion(_ question: Question) {
        gameState = .questionSelected(question)
    }
    
    func revealAnswer() {
        if case .questionSelected(let q) = gameState {
            gameState = .showingAnswer(q)
        }
    }
    
    func markCorrect(_ question: Question) {
        score += question.value
        markAnswered(question)
    }
    
    func markWrong(_ question: Question) {
        score -= question.value
        markAnswered(question)
    }
    
    private func markAnswered(_ question: Question) {
        for i in categories.indices {
            for j in categories[i].questions.indices {
                if categories[i].questions[j].id == question.id {
                    categories[i].questions[j].isAnswered = true
                }
            }
        }
        gameState = .idle
    }
}
