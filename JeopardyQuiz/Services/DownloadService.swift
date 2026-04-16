//
//  DownloadService.swift
//  JeopardyQuiz
//
//  Created by Jesyus on 15/04/26.
//

import Foundation
import Combine

enum DownloadState: Equatable {
    case idle
    case checkingServer
    case checkingUpdates
    case downloading(progress: Double)
    case downloadingMedia(current: Int, total: Int)
    case completed
    case upToDate
    case error(String)
}

@MainActor
class DownloadService: ObservableObject {

    static let shared = DownloadService()

    @Published var state: DownloadState = .idle
    @Published var localData: DownloadResponse? = nil
    @Published var localVersion: Int? = nil

    // MARK: - Init

    init() {
        Task {
            await loadLocalData()
        }
    }

    // MARK: - Carica dati locali

    func loadLocalData() async {
        localData    = try? LocalStorageService.shared.loadDownloadData()
        localVersion = LocalStorageService.shared.loadVersion()
    }

    // MARK: - Flusso download completo

    func startDownload() async {
        state = .checkingServer
        do {
            try await NetworkService.shared.wakeUpServer()
        } catch {
            state = .error("Server non raggiungibile. Controlla la connessione e riprova.")
            return
        }

        state = .checkingUpdates
        do {
            let remoteVersion = try await NetworkService.shared.fetchVersion()
            if let local = localVersion, local >= remoteVersion.version {
                state = .upToDate
                return
            }
        } catch {
            // Se non riesce a controllare la versione procede comunque
        }

        state = .downloading(progress: 0.0)

        let downloadData: DownloadResponse
        do {
            downloadData = try await NetworkService.shared.downloadAll()
            state = .downloading(progress: 0.8)
        } catch {
            state = .error("Errore nel download dei dati: \(error.localizedDescription)")
            return
        }

        do {
            try LocalStorageService.shared.saveDownloadData(downloadData)
            try LocalStorageService.shared.saveVersion(
                Int(Date().timeIntervalSince1970)
            )
        } catch {
            state = .error("Errore nel salvataggio dei dati: \(error.localizedDescription)")
            return
        }

        await loadLocalData()
        state = .completed
    }

    // MARK: - Elimina dati locali

    func deleteLocalData() async {
        do {
            try LocalStorageService.shared.deleteAll()
            localData    = nil
            localVersion = nil
            state        = .idle
        } catch {
            state = .error("Errore nell'eliminazione: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers UI

    var isReadyToPlay: Bool {
        localData != nil
    }

    var statusMessage: String {
        switch state {
        case .idle:
            return localData == nil
                ? "Nessun quiz scaricato"
                : "Quiz pronto"
        case .checkingServer:
            return "Connessione al server in corso..."
        case .checkingUpdates:
            return "Controllo aggiornamenti..."
        case .downloading(let p):
            return "Download dati... \(Int(p * 100))%"
        case .downloadingMedia(let c, let t):
            return "Download media: \(c)/\(t)"
        case .completed:
            return "Download completato ✓"
        case .upToDate:
            return "Quiz già aggiornato ✓"
        case .error(let msg):
            return "Errore: \(msg)"
        }
    }
}
