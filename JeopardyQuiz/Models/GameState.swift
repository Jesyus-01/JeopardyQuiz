//
//  GameState.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//


import Foundation

enum GameState: Equatable {
    case idle
    case questionSelected(Question)
    case showingAnswer(Question)
    case gameOver
}
