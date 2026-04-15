//
//  Category.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//


import Foundation

struct Category: Codable, Identifiable {
    let categoryId: Int
    let name: String
    let slug: String
    let requiresMedia: Bool
    let expectedMediaType: String?   // "image" | "audio" | nil
    let mediaSubdir: String?         // sottocartella su R2

    var id: Int { categoryId }

    enum CodingKeys: String, CodingKey {
        case categoryId        = "category_id"
        case name, slug
        case requiresMedia     = "requires_media"
        case expectedMediaType = "expected_media_type"
        case mediaSubdir       = "media_subdir"
    }
}
