//
//  GameState.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//

import Foundation

// Stato del gioco a livello di navigazione
enum AppScreen {
    case home
    case playerSetup
    case board
    case recap
}

// Stato del modal domanda
enum QuestionModalState: Equatable {
    case hidden
    case showing(questionId: Int)
}

// Cella del tabellone
struct BoardCell: Identifiable {
    // id univoco: "Trama_3" (categoria_difficulty)
    var id: String { "\(categoryName)_\(difficultyLevel)" }
    let categoryName: String
    let difficultyLevel: Int
    let points: Int              // 100 * difficultyLevel
    let question: Question
    var isPlayed: Bool = false
}
