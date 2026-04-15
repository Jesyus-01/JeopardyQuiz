//
//  LocalStorageService.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 15/04/26.
//

import Foundation

final class LocalStorageService {

    static let shared = LocalStorageService()

    // MARK: - Percorsi su disco

    private let fileManager = FileManager.default

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Cartella principale: Documents/jeopardy/
    private var jeopardyDir: URL {
        documentsURL.appendingPathComponent("jeopardy", isDirectory: true)
    }

    /// File JSON con tutti i dati scaricati
    private var dataFileURL: URL {
        jeopardyDir.appendingPathComponent("data.json")
    }

    /// File con il timestamp dell'ultima versione scaricata
    private var versionFileURL: URL {
        jeopardyDir.appendingPathComponent("version.txt")
    }

    /// Cartella media: Documents/jeopardy/media/
    private var mediaDir: URL {
        jeopardyDir.appendingPathComponent("media", isDirectory: true)
    }

    // MARK: - Setup

    func createDirectoriesIfNeeded() throws {
        try fileManager.createDirectory(at: jeopardyDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: mediaDir, withIntermediateDirectories: true)
    }

    // MARK: - Dati JSON

    /// Salva la risposta completa di /api/download su disco
    func saveDownloadData(_ data: DownloadResponse) throws {
        try createDirectoriesIfNeeded()
        let encoded = try JSONEncoder().encode(data)
        try encoded.write(to: dataFileURL, options: .atomic)
    }

    /// Legge i dati salvati dal disco (nil se non esistono)
    func loadDownloadData() throws -> DownloadResponse? {
        guard fileManager.fileExists(atPath: dataFileURL.path) else { return nil }
        let data = try Data(contentsOf: dataFileURL)
        return try JSONDecoder().decode(DownloadResponse.self, from: data)
    }

    /// Controlla se esistono dati scaricati
    var hasLocalData: Bool {
        fileManager.fileExists(atPath: dataFileURL.path)
    }

    // MARK: - Versione

    /// Salva il timestamp versione DB
    func saveVersion(_ version: Int) throws {
        try createDirectoriesIfNeeded()
        try String(version).write(to: versionFileURL, atomically: true, encoding: .utf8)
    }

    /// Legge il timestamp versione salvato localmente (nil se non esiste)
    func loadVersion() -> Int? {
        guard fileManager.fileExists(atPath: versionFileURL.path),
              let str = try? String(contentsOf: versionFileURL, encoding: .utf8),
              let version = Int(str.trimmingCharacters(in: .whitespacesAndNewlines))
        else { return nil }
        return version
    }

    // MARK: - Media

    /// Percorso locale di un file media dato il filename
    func localMediaURL(for filename: String) -> URL {
        mediaDir.appendingPathComponent(filename)
    }

    /// Controlla se un file media è già scaricato
    func isMediaDownloaded(filename: String) -> Bool {
        fileManager.fileExists(atPath: localMediaURL(for: filename).path)
    }

    /// Salva un file media su disco
    func saveMedia(data: Data, filename: String) throws {
        try createDirectoriesIfNeeded()
        let dest = localMediaURL(for: filename)
        try data.write(to: dest, options: .atomic)
    }

    /// Elimina tutti i dati (JSON + media + versione)
    func deleteAll() throws {
        if fileManager.fileExists(atPath: jeopardyDir.path) {
            try fileManager.removeItem(at: jeopardyDir)
        }
    }

    /// Dimensione totale dei dati scaricati (in bytes)
    func totalStorageUsed() -> Int64 {
        guard fileManager.fileExists(atPath: jeopardyDir.path) else { return 0 }
        guard let enumerator = fileManager.enumerator(
            at: jeopardyDir,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        ) else { return 0 }

        var total: Int64 = 0
        for case let url as URL in enumerator {
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            total += Int64(size)
        }
        return total
    }

    /// Formatta la dimensione in MB leggibile
    func formattedStorageSize() -> String {
        let bytes = totalStorageUsed()
        let mb = Double(bytes) / 1_048_576
        return String(format: "%.1f MB", mb)
    }
    
    // Aggiungere in LocalStorageService — versione sincrona per le View
    nonisolated func localMediaURLSync(for filename: String) -> URL {
        let docs = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs
            .appendingPathComponent("jeopardy")
            .appendingPathComponent("media")
            .appendingPathComponent(filename)
    }
}
