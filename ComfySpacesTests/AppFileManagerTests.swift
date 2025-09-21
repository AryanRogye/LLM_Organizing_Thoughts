//
//  AppFileManagerTests.swift
//  ComfySpacesTests
//
//  Validates RecordingItem saving/loading, legacy adoption,
//  metadata updates, and deletion behavior.
//

import Foundation
import Testing
@testable import ComfySpaces

struct AppFileManagerTests {
    
    // MARK: - Helpers
    private func docsURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    private func recordingsBaseURL() throws -> URL {
        let base = try docsURL().appendingPathComponent("Recordings", isDirectory: true)
        if !FileManager.default.fileExists(atPath: base.path) {
            try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        }
        return base
    }
    
    private func cleanRecordingsDirectory() throws {
        let base = try recordingsBaseURL()
        if FileManager.default.fileExists(atPath: base.path) {
            let contents = try FileManager.default.contentsOfDirectory(at: base, includingPropertiesForKeys: nil)
            for url in contents {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
    
    private func makeEmptyCAF(at url: URL) throws {
        let data = Data("CAF_TEST".utf8)
        try data.write(to: url)
    }
    
    private struct TestMeta: Codable {
        var createdAt: Date
        var duration: TimeInterval
        var emoji: String?
        var name: String?
    }
    
    private func writeMeta(_ meta: TestMeta, inFolder folder: URL) throws {
        let url = folder.appendingPathComponent("meta.json")
        let data = try JSONEncoder().encode(meta)
        try data.write(to: url, options: [.atomic])
    }
    
    private func makeNewStyleBundle(createdAt: Date, duration: TimeInterval, emoji: String? = nil, name: String? = nil) throws -> URL {
        let base = try recordingsBaseURL()
        let folder = base.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let audio = folder.appendingPathComponent("audio.caf")
        try makeEmptyCAF(at: audio)
        try writeMeta(TestMeta(createdAt: createdAt, duration: duration, emoji: emoji, name: name), inFolder: folder)
        return audio
    }
    
    private func uniqueLegacyURL(prefix: String) throws -> URL {
        try docsURL().appendingPathComponent("\(prefix)_\(UUID().uuidString).caf")
    }
    
    // MARK: - Tests
    @Test
    func makeRecordingItem_adoptsLegacyFile_intoNewFolder_withMeta() throws {
        try cleanRecordingsDirectory()
        let fm = AppFileManager()
        
        // Create a legacy file in Documents
        let legacy = try uniqueLegacyURL(prefix: "legacy_test")
        if FileManager.default.fileExists(atPath: legacy.path) { try? FileManager.default.removeItem(at: legacy) }
        try makeEmptyCAF(at: legacy)
        
        let item = try fm.makeRecordingItem(from: legacy)
        
        // Original removed, new-style location exists
        #expect(!FileManager.default.fileExists(atPath: legacy.path))
        #expect(FileManager.default.fileExists(atPath: item.url.path))
        
        // Must live under Documents/Recordings/<uuid>/audio.caf with meta.json
        let folder = item.url.deletingLastPathComponent()
        #expect(folder.deletingLastPathComponent().lastPathComponent == "Recordings")
        let metaURL = folder.appendingPathComponent("meta.json")
        #expect(FileManager.default.fileExists(atPath: metaURL.path))
    }
    
    @Test
    func makeRecordingItem_newStyle_keepsLocation_andReadsMeta() throws {
        try cleanRecordingsDirectory()
        let fm = AppFileManager()
        
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let audio = try makeNewStyleBundle(createdAt: date, duration: 123, emoji: "🎧", name: "Focus")
        
        let item = try fm.makeRecordingItem(from: audio)
        #expect(item.url == audio)
        #expect(item.date == date)
        #expect(item.duration == 123)
        #expect(item.emoji == "🎧")
        #expect(item.name == "Focus")
    }
    
    @Test
    func loadRecordings_readsAll_andSortsByDateDescending() throws {
        try cleanRecordingsDirectory()
        let fm = AppFileManager()
        
        let early = Date(timeIntervalSince1970: 1_650_000_000)
        let late  = Date(timeIntervalSince1970: 1_750_000_000)
        _ = try makeNewStyleBundle(createdAt: early, duration: 10, emoji: "🕰️", name: "Early")
        _ = try makeNewStyleBundle(createdAt: late,  duration: 20, emoji: "⏱️", name: "Late")
        
        let items = try fm.loadRecordings()
        // Global sort invariant: dates are non-increasing
        let isSorted = zip(items, items.dropFirst()).allSatisfy { $0.date >= $1.date }
        #expect(isSorted)
        
        // Ensure our inserted items are present
        let idxEarly = items.firstIndex(where: { $0.name == "Early" })
        let idxLate  = items.firstIndex(where: { $0.name == "Late" })
        let earlyIndex = try #require(idxEarly)
        let lateIndex  = try #require(idxLate)
        // And "Late" (newer) appears before "Early"
        #expect(lateIndex < earlyIndex)
    }
    
    @Test
    func setEmojiAndName_updatesMeta_andReflectedOnReload() throws {
        try cleanRecordingsDirectory()
        let fm = AppFileManager()
        
        let legacy = try uniqueLegacyURL(prefix: "to_update")
        if FileManager.default.fileExists(atPath: legacy.path) { try? FileManager.default.removeItem(at: legacy) }
        try makeEmptyCAF(at: legacy)
        var item = try fm.makeRecordingItem(from: legacy)
        
        item.emoji = "💡"
        fm.setEmoji(for: item)
        item.name = "Idea"
        fm.setName(for: item)
        
        let reloaded = try fm.loadRecordings()
        let same = try #require(reloaded.first(where: { $0.id == item.id }))
        #expect(same.emoji == "💡")
        #expect(same.name == "Idea")
    }
    
    @Test
    func delete_removesRecordingFolder() throws {
        try cleanRecordingsDirectory()
        let fm = AppFileManager()
        
        let legacy = try uniqueLegacyURL(prefix: "to_delete")
        if FileManager.default.fileExists(atPath: legacy.path) { try? FileManager.default.removeItem(at: legacy) }
        try makeEmptyCAF(at: legacy)
        let item = try fm.makeRecordingItem(from: legacy)
        let folder = item.url.deletingLastPathComponent()
        #expect(FileManager.default.fileExists(atPath: folder.path))
        
        try fm.delete(item)
        #expect(!FileManager.default.fileExists(atPath: folder.path))
    }
}
