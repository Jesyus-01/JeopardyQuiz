//
//  Avatar.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 15/04/26.
//

import Foundation

struct Avatar: Codable, Identifiable {
    let avatarId: String            // ← String
    let code: String
    let filename: String
    let label: String
    
    var id: String { avatarId }
    
    enum CodingKeys: String, CodingKey {
        case avatarId = "avatar_id"
        case code, filename, label
    }
}
