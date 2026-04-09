//
//  TriviaAPIService.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 09/04/26.
//


import Foundation

struct TriviaAPIService {
    static let baseURL = "https://opentdb.com/api.php"
    
    static func buildURL(amount: Int, category: Int? = nil) -> URL? {
        var components = URLComponents(string: baseURL)
        var queryItems = [
            URLQueryItem(name: "amount", value: "\(amount)"),
            URLQueryItem(name: "type", value: "multiple")
        ]
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: "\(category)"))
        }
        components?.queryItems = queryItems
        return components?.url
    }
}