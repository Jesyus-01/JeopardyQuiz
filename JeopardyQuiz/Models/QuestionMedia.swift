//
//  QuestionMedia.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 15/04/26.
//

import Foundation

struct QuestionMedia: Codable, Identifiable {
    let mediaId: Int
    let questionId: Int
    let mediaType: String    // "image" | "audio"
    let filename: String

    var id: Int { mediaId }

    enum CodingKeys: String, CodingKey {
        case mediaId    = "media_id"
        case questionId = "question_id"
        case mediaType  = "media_type"
        case filename
    }
}
