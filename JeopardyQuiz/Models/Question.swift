//
//  Question.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//
import Foundation

enum QuestionType: String, Codable {
    case open            = "OPEN"
    case multipleChoice  = "MCQ"
    case image           = "IMAGE"
    case audio           = "AUDIO"
}

struct Question: Codable, Identifiable {
    let questionId: String
    let categoryId: String
    let text: String
    let questionType: QuestionType   // ← torna da String a QuestionType
    let difficultyLevel: Int
    let basePoints: Int
    let correctOpenAnswer: String?
    let externalCode: String

    var id: String { questionId }
    
    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case categoryId = "category_id"
        case text
        case questionType = "question_type"
        case difficultyLevel = "difficulty_level"
        case basePoints = "base_points"
        case correctOpenAnswer = "correct_open_answer"
        case externalCode = "external_code"
    }
}
