//
//  NetworkService.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 15/04/26.
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case serverUnreachable
    case decodingFailed(Error)
    case httpError(Int)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:             return "URL non valido."
        case .serverUnreachable:      return "Server non raggiungibile. Controlla la connessione."
        case .decodingFailed(let e):  return "Errore dati: \(e.localizedDescription)"
        case .httpError(let code):    return "Errore server (codice \(code))."
        case .unknown(let e):         return e.localizedDescription
        }
    }
}

enum ServerStatus {
    case idle
    case checking
    case awake
    case offline
}

final class NetworkService {

    static let shared = NetworkService()

    private let baseURL = "https://jeopardy-api-djeo.onrender.com/api"

    // Sessione con timeout generoso per il cold start di Render
    private let wakeSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 65
        config.timeoutIntervalForResource = 65
        return URLSession(configuration: config)
    }()

    // Sessione normale per tutte le altre chiamate
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    // MARK: - Wake Up

    /// Chiama /health e aspetta fino a 65s (cold start Render)
    func wakeUpServer() async throws {
        guard let url = URL(string: "https://jeopardy-api-djeo.onrender.com/health") else {
            throw NetworkError.invalidURL
        }
        do {
            let (_, response) = try await wakeSession.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw NetworkError.serverUnreachable
            }
        } catch let urlError as URLError {
            if urlError.code == .timedOut || urlError.code == .notConnectedToInternet {
                throw NetworkError.serverUnreachable
            }
            throw NetworkError.unknown(urlError)
        }
    }

    // MARK: - Download

    /// GET /api/download — scarica tutto (categorie, domande, opzioni, media, avatar)
    func downloadAll() async throws -> DownloadResponse {
        return try await get(path: "/download", session: session)
    }

    /// GET /api/download/version — controlla timestamp aggiornamento DB
    func fetchVersion() async throws -> VersionResponse {
        return try await get(path: "/download/version", session: session)
    }

    // MARK: - Quiz

    /// GET /api/quiz/availability — quante domande non usate per ogni cella
    func fetchAvailability() async throws -> AvailabilityResponse {
        return try await get(path: "/quiz/availability", session: session)
    }

    /// GET /api/quiz/generate — genera un quiz 5x5 da domande non ancora usate
    func generateQuiz() async throws -> GenerateResponse {
        return try await get(path: "/quiz/generate", session: session)
    }

    // MARK: - Media Manifest

    /// GET /api/media/manifest — lista di tutti i file media con URL R2
    func fetchMediaManifest() async throws -> MediaManifestResponse {
        return try await get(path: "/media/manifest", session: session)
    }

    // MARK: - Helpers

    private func get<T: Decodable>(path: String, session: URLSession) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw NetworkError.invalidURL
        }

        do {
            let (data, response) = try await session.data(from: url)

            if let http = response as? HTTPURLResponse,
               !(200...299).contains(http.statusCode) {
                throw NetworkError.httpError(http.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingFailed(error)
            }

        } catch let error as NetworkError {
            throw error
        } catch let urlError as URLError {
            if urlError.code == .notConnectedToInternet || urlError.code == .timedOut {
                throw NetworkError.serverUnreachable
            }
            throw NetworkError.unknown(urlError)
        } catch {
            throw NetworkError.unknown(error)
        }
    }
}
