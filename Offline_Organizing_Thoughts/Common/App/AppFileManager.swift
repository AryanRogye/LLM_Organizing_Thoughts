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
    
    /// turn a single file URL into a RecordingItem
    public func makeRecordingItem(from url: URL) throws -> RecordingItem {
        let vals = try url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
        let date = vals.creationDate ?? vals.contentModificationDate ?? Date()
        
        let asset = AVURLAsset(url: url)
        
        var duration: Double = 0
        if let audioFile = try? AVAudioFile(forReading: url) {
            let frames = Double(audioFile.length)
            let sampleRate = audioFile.fileFormat.sampleRate
            let secs = frames / sampleRate
            duration = secs.isFinite ? secs : 0
        }
        
        return RecordingItem(url: url, date: date, duration: duration)
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
        
        /// Get Documents Folder
        let docs = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        // grab files (non-recursive); toggle .skipsSubdirectoryDescendants
        let urls = try FileManager.default.contentsOfDirectory(
            at: docs,
            includingPropertiesForKeys: [
                .creationDateKey, .contentModificationDateKey, .fileSizeKey, .isRegularFileKey
            ],
            options: [.skipsHiddenFiles]
        )
        
        let audioURLs = urls.filter { url in
            (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
            && exts.contains(url.pathExtension.lowercased())
        }
        
        // map to RecordingItem, computing duration via AVAudioFile
        let items: [RecordingItem] = audioURLs.compactMap { url in
            let vals = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
            let date = vals?.creationDate ?? vals?.contentModificationDate ?? Date()
            
            // duration via AVAudioFile (avoids deprecated AVAsset.duration)
            var duration: Double = 0
            if let audioFile = try? AVAudioFile(forReading: url) {
                let frames = Double(audioFile.length)
                let sampleRate = audioFile.fileFormat.sampleRate
                let secs = frames / sampleRate
                duration = secs.isFinite ? secs : 0
            }
            
            return RecordingItem(url: url, date: date, duration: duration)
        }
        
        // newest first
        return items.sorted { $0.date > $1.date }
    }
    
    // MARK: - Delete a recording
    public func delete(_ item: RecordingItem) throws {
        try FileManager.default.removeItem(at: item.url)
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

