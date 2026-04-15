//
//  QuestionMedia.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 15/04/26.
//

import Foundation

struct QuestionMedia: Codable, Identifiable {
    let mediaId: String             // ← String
    let questionId: String          // ← String
    let mediaType: String           // "AUDIO" | "IMAGE"
    let filename: String
    
    var id: String { mediaId }
    
    enum CodingKeys: String, CodingKey {
        case mediaId = "media_id"
        case questionId = "question_id"
        case mediaType = "media_type"
        case filename
    }
}
