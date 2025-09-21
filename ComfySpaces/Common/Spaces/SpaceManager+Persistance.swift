//
//  SpaceManager+Persistance.swift
//  ComfySpaces
//
//  Created by Aryan Rogye on 9/21/25.
//

import Foundation
// ==============================================================
// Persistence
// ==============================================================

// ==============================================================
// MARK: - Snapshot Model
// ==============================================================
/// A lightweight, codable snapshot of all spaces for on-disk persistence.
private struct SpacesSnapshot: Codable {
    var spaces: [Space]
}

extension SpacesManager {
    // ==============================================================
    // MARK: - File Location
    // ==============================================================
    
    /// The on-disk file name for storing spaces.
    private static let fileName = "BoardStore.json" // keep name for backward compatibility

    /// Location of the JSON file on disk.
    static var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }

    // ==============================================================
    // MARK: - JSON Helpers
    // ==============================================================
    /// Configure a JSON encoder for saving.
    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        // Make the file human-readable and stable on disk.
        if #available(iOS 13.0, macOS 10.15, *) {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        } else {
            encoder.outputFormatting = [.prettyPrinted]
        }
        return encoder
    }

    /// Configure a JSON decoder for loading.
    private static func makeDecoder() -> JSONDecoder {
        JSONDecoder()
    }
    
    // ==============================================================
    // MARK: - Saving
    // ==============================================================
    func save() {
        let snapshot = SpacesSnapshot(spaces: spaces)
        do {
            let encoder = Self.makeEncoder()
            let data = try encoder.encode(snapshot)
            // Ensure parent directory exists and exclude it from iCloud backups.
            try Self.ensureParentDir(for: Self.fileURL)
            try data.write(to: Self.fileURL, options: .atomic)
        } catch {
#if DEBUG
            print("Spaces save error at \(Self.fileURL.path):", error)
#endif
        }
    }
    
    // ==============================================================
    // MARK: - Loading
    // ==============================================================
    func load() {
        do {
            // If there's no file yet, there's nothing to load.
            guard FileManager.default.fileExists(atPath: Self.fileURL.path) else { return }

            let data = try Data(contentsOf: Self.fileURL)
            let decoder = Self.makeDecoder()
            let decoded = try decoder.decode(SpacesSnapshot.self, from: data)

            // Apply changes on the main queue since this likely affects UI state.
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.spaces = decoded.spaces

                // Keep selection pointing at the live instance from `spaces`.
                if let selID = self.selectedSpace?.id,
                   let idx = self.spaces.firstIndex(where: { $0.id == selID }) {
                    self.selectedSpace = self.spaces[idx]
                }
            }
        } catch {
#if DEBUG
            print("Spaces load error at \(Self.fileURL.path):", error)
#endif
        }
    }
    
    // ==============================================================
    // MARK: - Directory Utilities
    // ==============================================================
    private static func ensureParentDir(for url: URL) throws {
        let fm = FileManager.default
        let dir = url.deletingLastPathComponent()

        // Create the directory if it doesn't exist yet.
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        // Exclude from iCloud backups to avoid unnecessary syncs.
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var modifiableDir = dir
        try? modifiableDir.setResourceValues(values)
    }
}

