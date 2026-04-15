//
//  QuizGeneratorService.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 15/04/26.
//
import Foundation

struct GeneratedBoard {
    let cells: [[BoardCell]]           // [colonna(categoria)][riga(difficulty)]
    let totalQuestions: Int            // domande totali che verranno giocate
}

final class QuizGeneratorService {

    static let shared = QuizGeneratorService()

    // Ordine fisso delle categorie sul tabellone
    private let categoryOrder = ["Ambientazione", "Domande", "Opening", "Personaggio", "Trama"]
    private let difficultyPoints = [1: 100, 2: 200, 3: 300, 4: 400, 5: 500]

    // MARK: - Generazione tabellone

    /// Genera un tabellone 5×5 pescando 1 domanda random per ogni cella
    /// dai dati scaricati localmente. Non tocca il server.
    func generateBoard(from data: DownloadResponse, playerCount: Int) -> GeneratedBoard? {

        // Costruisce un dizionario nomeCategoria → Category
        let categoryMap: [String: Category] = Dictionary(
            uniqueKeysWithValues: data.categories.map { ($0.name, $0) }
        )

        // Raggruppa le domande per (categoryName, difficulty)
        var pool: [String: [Question]] = [:]
        for question in data.questions {
            guard let cat = data.categories.first(where: { $0.categoryId == question.categoryId })
            else { continue }
            let key = poolKey(category: cat.name, difficulty: question.difficultyLevel)
            pool[key, default: []].append(question)
        }

        // Controlla che ogni cella abbia almeno 1 domanda disponibile
        var missingCells: [String] = []
        for catName in categoryOrder {
            for difficulty in 1...5 {
                let key = poolKey(category: catName, difficulty: difficulty)
                if pool[key]?.isEmpty ?? true {
                    missingCells.append("\(catName) lv.\(difficulty)")
                }
            }
        }

        guard missingCells.isEmpty else {
            print("⚠️ QuizGenerator: celle mancanti → \(missingCells.joined(separator: ", "))")
            return nil
        }

        // Costruisce la griglia selezionando 1 domanda random per cella
        // Usa un Set per tracciare gli ID già usati (no duplicati nella stessa partita)
        var usedIds = Set<String>()
        let columns: [[BoardCell]] = categoryOrder.compactMap { catName -> [BoardCell]? in
            guard categoryMap[catName] != nil else { return nil }

            let rows: [BoardCell] = (1...5).compactMap { difficulty -> BoardCell? in
                let key = poolKey(category: catName, difficulty: difficulty)
                guard var candidates = pool[key] else { return nil }

                // Rimuovi domande già usate in questa partita
                candidates = candidates.filter { !usedIds.contains($0.questionId) }

                // Fallback: se tutti gli ID sono già usati, riusa dal pool originale
                if candidates.isEmpty {
                    candidates = pool[key] ?? []
                }

                guard let picked = candidates.randomElement() else { return nil }
                usedIds.insert(picked.questionId)

                return BoardCell(
                    categoryName: catName,
                    difficultyLevel: difficulty,
                    points: difficultyPoints[difficulty] ?? difficulty * 100,
                    question: picked
                )
            }

            return rows.isEmpty ? nil : rows
        }

        // Calcola domande totali che verranno giocate (giro completo)
        let totalCells = columns.flatMap { $0 }.count
        let questionsPerPlayer = totalCells / playerCount
        let totalToPlay = questionsPerPlayer * playerCount

        return GeneratedBoard(cells: columns, totalQuestions: totalToPlay)
    }

    // MARK: - Statistiche disponibilità

    /// Restituisce quante domande sono disponibili per ogni cella
    /// Utile per mostrare info nella HomeView
    func availabilityMap(from data: DownloadResponse) -> [String: Int] {
        var map: [String: Int] = [:]
        for question in data.questions {
            guard let cat = data.categories.first(where: { $0.categoryId == question.categoryId })
            else { continue }
            let key = poolKey(category: cat.name, difficulty: question.difficultyLevel)
            map[key, default: 0] += 1
        }
        return map
    }

    /// Numero minimo di domande per cella (= quante partite complete si possono giocare)
    func availableGamesCount(from data: DownloadResponse) -> Int {
        let map = availabilityMap(from: data)
        let counts = categoryOrder.flatMap { catName in
            (1...5).map { difficulty in
                map[poolKey(category: catName, difficulty: difficulty)] ?? 0
            }
        }
        return counts.min() ?? 0
    }

    // MARK: - Helper

    private func poolKey(category: String, difficulty: Int) -> String {
        "\(category)_\(difficulty)"
    }
}
