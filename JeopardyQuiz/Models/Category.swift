//
//  Category.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//


import Foundation

struct Category: Codable, Identifiable {
    let categoryId: String          // ← String, non Int
    let name: String
    let slug: String
    let requiresMedia: Bool
    let expectedMediaType: String?  // ← opzionale (può essere null)
    let mediaSubdir: String?        // ← opzionale (può essere null)
    
    var id: String { categoryId }
    
    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case name, slug
        case requiresMedia = "requires_media"
        case expectedMediaType = "expected_media_type"
        case mediaSubdir = "media_subdir"
    }
}
