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

struct Question: Codable, Identifiable, Equatable {
    let questionId: Int
    let categoryId: Int
    let text: String
    let questionType: QuestionType
    let difficultyLevel: Int     // 1–5
    let basePoints: Int          // 100–500
    let correctOpenAnswer: String?
    let externalCode: String?    // filename audio/immagine quando non c'è question_media

    var id: Int { questionId }

    enum CodingKeys: String, CodingKey {
        case questionId          = "question_id"
        case categoryId          = "category_id"
        case text
        case questionType        = "question_type"
        case difficultyLevel     = "difficulty_level"
        case basePoints          = "base_points"
        case correctOpenAnswer   = "correct_open_answer"
        case externalCode        = "external_code"
    }
}
