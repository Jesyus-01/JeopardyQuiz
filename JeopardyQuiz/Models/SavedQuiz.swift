// SavedQuiz.swift

import Foundation

struct SavedQuiz: Identifiable, Codable, Sendable {
    let id:          UUID
    let generatedAt: Date
    let board:       [[SavedBoardCell]]
    var quizNumber:  Int = 0

    var displayName: String {
        "Quiz \(quizNumber)"
    }
}

struct SavedBoardCell: Codable, Sendable {
    let categoryName:    String
    let difficultyLevel: Int
    let points:          Int
    let question:        SavedQuestion
    var isPlayed:        Bool

    func toBoardCell() -> BoardCell {
        BoardCell(
            categoryName:    categoryName,
            difficultyLevel: difficultyLevel,
            points:          points,
            question:        question.toQuestion()
        )
    }

    static func from(_ cell: BoardCell) -> SavedBoardCell {
        SavedBoardCell(
            categoryName:    cell.categoryName,
            difficultyLevel: cell.difficultyLevel,
            points:          cell.points,
            question:        SavedQuestion.from(cell.question),
            isPlayed:        false
        )
    }
}

struct SavedQuestion: Codable, Sendable {
    let questionId:        String
    let categoryId:        String
    let text:              String
    let questionType:      String
    let difficultyLevel:   Int
    let basePoints:        Int
    let correctOpenAnswer: String?
    let externalCode:      String

    func toQuestion() -> Question {
        Question(
            questionId:        questionId,
            categoryId:        categoryId,
            text:              text,
            questionType:      QuestionType(rawValue: questionType) ?? .open,
            difficultyLevel:   difficultyLevel,
            basePoints:        basePoints,
            correctOpenAnswer: correctOpenAnswer,
            externalCode:      externalCode
        )
    }

    static func from(_ q: Question) -> SavedQuestion {
        SavedQuestion(
            questionId:        q.questionId,
            categoryId:        q.categoryId,
            text:              q.text,
            questionType:      q.questionType.rawValue,
            difficultyLevel:   q.difficultyLevel,
            basePoints:        q.basePoints,
            correctOpenAnswer: q.correctOpenAnswer,
            externalCode:      q.externalCode
        )
    }
}
