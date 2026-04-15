//
//  ChoiceOption.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 15/04/26.
//

import Foundation

struct ChoiceOption: Codable, Identifiable {
    let optionId: Int
    let questionId: Int
    let optionText: String
    let optionOrder: Int
    let isCorrect: Bool

    var id: Int { optionId }

    enum CodingKeys: String, CodingKey {
        case optionId    = "option_id"
        case questionId  = "question_id"
        case optionText  = "option_text"
        case optionOrder = "option_order"
        case isCorrect   = "is_correct"
    }
}
