//
//  Question.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//
import Foundation

enum QuestionType: String, Codable {
    case open            = "open"
    case multipleChoice  = "multiple_choice"
    case image           = "image"
    case audio           = "audio"
}

struct Question: Codable, Identifiable {
    let questionId: String          // ← String
    let categoryId: String          // ← String
    let text: String
    let questionType: String        // "OPEN" | "MCQ"
    let difficultyLevel: Int
    let basePoints: Int
    let correctOpenAnswer: String?  // ← opzionale (null per le MCQ)
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
