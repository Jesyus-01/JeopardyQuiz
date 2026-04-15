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
    case checkingServer          // ping /health
    case checkingUpdates         // confronto versione
    case downloading(progress: Double)  // 0.0 → 1.0
    case downloadingMedia(current: Int, total: Int)
    case completed
    case upToDate                // già aggiornato, niente da fare
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
        // Step 1: sveglia il server
        state = .checkingServer
        do {
            try await NetworkService.shared.wakeUpServer()
        } catch {
            state = .error("Server non raggiungibile. Controlla la connessione e riprova.")
            return
        }

        // Step 2: controlla se c'è una versione più nuova
        state = .checkingUpdates
        do {
            let remoteVersion = try await NetworkService.shared.fetchVersion()
            if let local = localVersion, local >= remoteVersion.version {
                state = .upToDate
                return
            }
        } catch {
            // Se non riesce a controllare la versione procede comunque
            // (potrebbe essere la prima volta)
        }

        // Step 3: scarica tutti i dati JSON
        state = .downloading(progress: 0.0)
        let downloadData: DownloadResponse
        do {
            downloadData = try await NetworkService.shared.downloadAll()
            state = .downloading(progress: 0.4)
        } catch {
            state = .error("Errore nel download dei dati: \(error.localizedDescription)")
            return
        }

        // Step 4: scarica il manifest dei media
        state = .downloading(progress: 0.5)
        let manifest: MediaManifestResponse
        do {
            manifest = try await NetworkService.shared.fetchMediaManifest()
            state = .downloading(progress: 0.6)
        } catch {
            state = .error("Errore nel manifest media: \(error.localizedDescription)")
            return
        }

        // Step 5: scarica i file media (immagini + audio) da Cloudflare R2
        let mediaFiles = manifest.files
        let total = mediaFiles.count
        var downloaded = 0

        for mediaFile in mediaFiles {
            // Salta se già scaricato
            let alreadyExists = LocalStorageService.shared.isMediaDownloaded(
                filename: mediaFile.filename
            )
            if alreadyExists {
                downloaded += 1
                state = .downloadingMedia(current: downloaded, total: total)
                continue
            }

            // Scarica da R2
            guard let url = URL(string: mediaFile.url) else { continue }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                try LocalStorageService.shared.saveMedia(
                    data: data,
                    filename: mediaFile.filename
                )
            } catch {
                // File non critico: logga e continua
                print("⚠️ Media non scaricato: \(mediaFile.filename) — \(error)")
            }

            downloaded += 1
            state = .downloadingMedia(current: downloaded, total: total)
        }

        // Step 6: salva JSON e versione su disco
        do {
            try LocalStorageService.shared.saveDownloadData(downloadData)
            try LocalStorageService.shared.saveVersion(
                Int(Date().timeIntervalSince1970)
            )
        } catch {
            state = .error("Errore nel salvataggio dei dati: \(error.localizedDescription)")
            return
        }

        // Step 7: aggiorna stato in memoria
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

    /// true se ci sono dati scaricati e pronti per giocare
    var isReadyToPlay: Bool {
        localData != nil
    }

    /// Testo descrittivo dello stato corrente per la UI
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
