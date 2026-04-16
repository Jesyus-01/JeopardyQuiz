//
//  DownloadData.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 15/04/26.
//

import Foundation

// MARK: - GET /api/download
struct DownloadResponse: Codable {
    let version: Int
    let categories: [Category]
    let questions: [Question]
    let choiceOptions: [ChoiceOption]
    let questionMedia: [QuestionMedia]
    let avatars: [Avatar]

    enum CodingKeys: String, CodingKey {
        case version
        case categories
        case questions
        case choiceOptions = "choiceOptions"   // camelCase nel JSON
        case questionMedia = "questionMedia"   // camelCase nel JSON
        case avatars
    }
}

// MARK: - GET /api/download/version
struct VersionResponse: Codable {
    let version: Int
}

// MARK: - GET /api/quiz/generate
struct GenerateResponse: Codable {
    let generatedAt: String
    let totalQuestions: Int
    let questions: [Question]
    let choiceOptions: [ChoiceOption]
    let questionMedia: [QuestionMedia]

    enum CodingKeys: String, CodingKey {
        case generatedAt    = "generatedAt"
        case totalQuestions = "totalQuestions"
        case questions
        case choiceOptions  = "choiceOptions"
        case questionMedia  = "questionMedia"
    }
}

// MARK: - GET /api/quiz/availability
struct AvailabilityResponse: Codable {
    let grid: [AvailabilityCell]
}

struct AvailabilityCell: Codable {
    let categoria: String
    let difficultyLevel: Int
    let disponibili: Int

    enum CodingKeys: String, CodingKey {
        case categoria
        case difficultyLevel = "difficulty_level"
        case disponibili
    }
}

// MARK: - GET /api/media/manifest
struct MediaManifestResponse: Codable {
    let files: [MediaManifestFile]
}

struct MediaManifestFile: Codable {
    let filename: String
    let mediaType: String
    let url: String

    enum CodingKeys: String, CodingKey {
        case filename
        case mediaType = "mediaType"
        case url
    }
}
