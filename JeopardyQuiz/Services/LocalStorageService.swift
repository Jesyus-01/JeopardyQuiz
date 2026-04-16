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

    /// Cartella media legacy: Documents/jeopardy/media/
    private var mediaDir: URL {
        jeopardyDir.appendingPathComponent("media", isDirectory: true)
    }

    // MARK: - Setup

    func createDirectoriesIfNeeded() throws {
        try fileManager.createDirectory(at: jeopardyDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: mediaDir, withIntermediateDirectories: true)
    }

    // MARK: - Dati JSON

    func saveDownloadData(_ data: DownloadResponse) throws {
        try createDirectoriesIfNeeded()
        let encoded = try JSONEncoder().encode(data)
        try encoded.write(to: dataFileURL, options: .atomic)
    }

    func loadDownloadData() throws -> DownloadResponse? {
        guard fileManager.fileExists(atPath: dataFileURL.path) else { return nil }
        let data = try Data(contentsOf: dataFileURL)
        return try JSONDecoder().decode(DownloadResponse.self, from: data)
    }

    var hasLocalData: Bool {
        fileManager.fileExists(atPath: dataFileURL.path)
    }

    // MARK: - Versione

    func saveVersion(_ version: Int) throws {
        try createDirectoriesIfNeeded()
        try String(version).write(to: versionFileURL, atomically: true, encoding: .utf8)
    }

    func loadVersion() -> Int? {
        guard fileManager.fileExists(atPath: versionFileURL.path),
              let str = try? String(contentsOf: versionFileURL, encoding: .utf8),
              let version = Int(str.trimmingCharacters(in: .whitespacesAndNewlines))
        else { return nil }
        return version
    }

    // MARK: - Media legacy su disco

    func localMediaURL(for filename: String) -> URL {
        mediaDir.appendingPathComponent(filename)
    }

    func isMediaDownloaded(filename: String) -> Bool {
        fileManager.fileExists(atPath: localMediaURL(for: filename).path)
    }

    func saveMedia(data: Data, filename: String) throws {
        try createDirectoriesIfNeeded()
        let dest = localMediaURL(for: filename)
        try data.write(to: dest, options: .atomic)
    }

    // MARK: - Bundle media (folder reference blu)

    private func bundledMediaURL(for filename: String, subdirectory: String) -> URL? {
        let nsFilename = filename as NSString
        let nameWithoutExt = nsFilename.deletingPathExtension
        let ext = nsFilename.pathExtension

        return Bundle.main.url(
            forResource: nameWithoutExt,
            withExtension: ext.isEmpty ? nil : ext,
            subdirectory: subdirectory
        )
    }

    /// Cerca il file prima nel Bundle (cartella blu), poi come fallback in Documents.
    func resolveMediaURL(for filename: String, subdirectories: [String]) -> URL? {
        let nsFilename = filename as NSString
        let nameWithoutExt = nsFilename.deletingPathExtension
        let ext = nsFilename.pathExtension

        // 1. Cerca nella root del bundle (Xcode appiattisce le folder reference)
        if let bundled = Bundle.main.url(
            forResource: nameWithoutExt,
            withExtension: ext.isEmpty ? nil : ext
        ) {
            return bundled
        }

        // 2. Cerca nelle sottocartelle (fallback per strutture diverse)
        for subdirectory in subdirectories {
            if let bundled = Bundle.main.url(
                forResource: nameWithoutExt,
                withExtension: ext.isEmpty ? nil : ext,
                subdirectory: subdirectory
            ) {
                return bundled
            }
        }

        // 3. Fallback: Documents/jeopardy/media/
        let localURL = localMediaURL(for: filename)
        if fileManager.fileExists(atPath: localURL.path) {
            return localURL
        }

        return nil
    }

    // MARK: - Pulizia

    func deleteAll() throws {
        if fileManager.fileExists(atPath: jeopardyDir.path) {
            try fileManager.removeItem(at: jeopardyDir)
        }
    }

    // MARK: - Storage info

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

    func formattedStorageSize() -> String {
        let bytes = totalStorageUsed()
        let mb = Double(bytes) / 1_048_576
        return String(format: "%.1f MB", mb)
    }
}
