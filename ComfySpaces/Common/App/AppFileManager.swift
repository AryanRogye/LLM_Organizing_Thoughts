//
//  AppFileManager.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import Foundation
import AVFoundation
import AVFAudio

final class AppFileManager {
    public init() {}
    
    // MARK: - Paths
    private func documentsURL() throws -> URL {
        try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }
    
    private func recordingsBaseURL() throws -> URL {
        let docs = try documentsURL()
        let base = docs.appendingPathComponent("Recordings", isDirectory: true)
        if !FileManager.default.fileExists(atPath: base.path) {
            try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        }
        return base
    }
    
    private func isNewStyleRecordingFile(_ url: URL) -> Bool {
        // new style: Documents/Recordings/<uuid>/audio.caf
        let parent = url.deletingLastPathComponent()
        return parent.deletingLastPathComponent().lastPathComponent == "Recordings"
    }
    
    // MARK: - Metadata
    private struct RecordingMeta: Codable {
        var createdAt: Date
        var duration: TimeInterval
        var emoji: String?
        var name: String?
    }
    
    private func metaURL(forFolder folder: URL) -> URL {
        folder.appendingPathComponent("meta.json")
    }
    
    private func readMeta(inFolder folder: URL) -> RecordingMeta? {
        let url = metaURL(forFolder: folder)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(RecordingMeta.self, from: data)
    }
    
    private func writeMeta(_ meta: RecordingMeta, inFolder folder: URL) {
        let url = metaURL(forFolder: folder)
        if let data = try? JSONEncoder().encode(meta) {
            try? data.write(to: url, options: [.atomic])
        }
    }
    
    private func audioURL(inFolder folder: URL) -> URL { folder.appendingPathComponent("audio.caf") }
    
    // MARK: - Helpers
    private func computeDuration(for url: URL) -> Double {
        var duration: Double = 0
        if let audioFile = try? AVAudioFile(forReading: url) {
            let frames = Double(audioFile.length)
            let sampleRate = audioFile.fileFormat.sampleRate
            let secs = frames / sampleRate
            duration = secs.isFinite ? secs : 0
        }
        return duration
    }
    
    private func computeDate(for url: URL) -> Date {
        let vals = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
        return vals?.creationDate ?? vals?.contentModificationDate ?? Date()
    }
    
    /// Turn a single file URL into a RecordingItem.
    /// If the URL points to a legacy file (Documents/*.caf), it is adopted
    /// into the new folder layout: Documents/Recordings/<uuid>/audio.caf with meta.json.
    public func makeRecordingItem(from url: URL) throws -> RecordingItem {
        let base = try recordingsBaseURL()
        
        // If already in new layout, read meta if present and return.
        if isNewStyleRecordingFile(url) {
            let folder = url.deletingLastPathComponent()
            let meta = readMeta(inFolder: folder)
            let date = meta?.createdAt ?? computeDate(for: url)
            let duration = meta?.duration ?? computeDuration(for: url)
            return RecordingItem(url: url, date: date, duration: duration, emoji: meta?.emoji, name: meta?.name)
        }
        
        // Legacy file: move into a new folder and persist meta.json
        let id = UUID().uuidString
        let folder = base.appendingPathComponent(id, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let dest = audioURL(inFolder: folder)
        try FileManager.default.moveItem(at: url, to: dest)
        
        let date = computeDate(for: dest)
        let duration = computeDuration(for: dest)
        let meta = RecordingMeta(createdAt: date, duration: duration, emoji: nil, name: nil)
        writeMeta(meta, inFolder: folder)
        
        return RecordingItem(url: dest, date: date, duration: duration, emoji: meta.emoji, name: meta.name)
    }
    
    #if DEBUG
    public func loadMockRecordings() -> [RecordingItem] {
        let now = Date()
        let tmp = FileManager.default.temporaryDirectory
        let calendar = Calendar.current
        let mocks: [RecordingItem] = (0..<8).map { i in
            let url = tmp.appendingPathComponent("Mock_Recording_\(i + 1).caf")
            let date = calendar.date(byAdding: .minute, value: -(i * 7), to: now) ?? now
            let duration = Double.random(in: 5...180)
            return RecordingItem(url: url, date: date, duration: duration)
        }
        // newest first
        return mocks.sorted { $0.date > $1.date }
    }
    #endif
    // MARK: - Load Recordings
    public func loadRecordings(exts: Set<String> = ["caf"]) throws -> [RecordingItem] {
        // New layout: enumerate folders under Documents/Recordings
        let base = try recordingsBaseURL()
        let folderURLs = try FileManager.default.contentsOfDirectory(
            at: base,
            includingPropertiesForKeys: [.isDirectoryKey, .creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ).filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        }
        
        var items: [RecordingItem] = []
        for folder in folderURLs {
            let audio = audioURL(inFolder: folder)
            guard FileManager.default.fileExists(atPath: audio.path) else { continue }
            let meta = readMeta(inFolder: folder)
            let date = meta?.createdAt ?? computeDate(for: audio)
            let duration = meta?.duration ?? computeDuration(for: audio)
            items.append(RecordingItem(url: audio, date: date, duration: duration, emoji: meta?.emoji, name: meta?.name))
        }
        
        // newest first
        return items.sorted { $0.date > $1.date }
    }
    
    // MARK: - Delete a recording
    public func delete(_ item: RecordingItem) throws {
        // With new layout as the only source, remove the recording folder.
        let folder = item.url.deletingLastPathComponent()
        do {
            try FileManager.default.removeItem(at: folder)
        } catch {
            // Fallback: try removing the file itself if folder removal fails.
            try FileManager.default.removeItem(at: item.url)
        }
    }

    // MARK: - Update Metadata
    public func setEmoji(for item: RecordingItem) {
        
        let url = item.url
        
        let folder = url.deletingLastPathComponent()
        var meta = readMeta(inFolder: folder) ?? RecordingMeta(
            createdAt: computeDate(for: url),
            duration: item.duration,
            emoji: item.emoji,
            name: item.name
        )
        meta.emoji = item.emoji
        writeMeta(meta, inFolder: folder)
    }
    public func setName(for item: RecordingItem) {
        
        let url = item.url
        
        let folder = url.deletingLastPathComponent()
        var meta = readMeta(inFolder: folder) ?? RecordingMeta(
            createdAt: computeDate(for: url),
            duration: item.duration,
            emoji: item.emoji,
            name: item.name
        )
        meta.name = item.name
        writeMeta(meta, inFolder: folder)
    }
    
    
    /// move from Temp → Documents (if you use the “confirm to save” flow)
    public func moveFromTempToDocuments(tempURL: URL) throws -> URL {
        let docs = try FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        let dest = docs.appendingPathComponent(tempURL.lastPathComponent)
        try FileManager.default.moveItem(at: tempURL, to: dest)
        return dest
    }
}
