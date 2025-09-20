//
//  TranscribeManager+Helpers.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import Foundation
import WhisperKit

extension TranscribeManager {
    /// Location where we want the Whisper models to live permanently.
    /// Application Support survives app restarts and won’t get purged by iOS like Caches can.
    private func appSupportURL() throws -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = base.appendingPathComponent(whisperFolderName, isDirectory: true)
        
        // Create folder if it doesn’t exist yet
        if !fm.fileExists(atPath: url.path) {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
        
        // Mark “don’t back up” so we don’t blow up iCloud with multi-hundred MB model files
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutable = url
        try mutable.setResourceValues(values)
        return url
    }
    
    /// WhisperKit’s default cache location. It *thinks* models are here.
    private func cacheURL() -> URL {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent(whisperFolderName, isDirectory: true)
    }
    
    /// Check if a given path is already a symlink
    private func isSymlink(_ url: URL) -> Bool {
        (try? FileManager.default.destinationOfSymbolicLink(atPath: url.path)) != nil
    }
    
    /// Replace Caches folder with a symlink → Application Support
    /// This way WhisperKit keeps using its default path, but the actual data lives permanently.
    private func replaceWithSymlink(from src: URL, to dest: URL) throws {
        let fm = FileManager.default
        if isSymlink(src) {
            // Already a symlink → verify destination, fix if wrong
            let current = try fm.destinationOfSymbolicLink(atPath: src.path)
            if URL(fileURLWithPath: current).standardizedFileURL != dest.standardizedFileURL {
                try fm.removeItem(at: src)
                try fm.createSymbolicLink(at: src, withDestinationURL: dest)
            }
            return
        }
        // If folder exists but isn’t a symlink, remove and replace with one
        if fm.fileExists(atPath: src.path) { try fm.removeItem(at: src) }
        try fm.createSymbolicLink(at: src, withDestinationURL: dest)
    }
    
    /// Safe wrapper around reading contents of a folder (returns [] if it doesn’t exist)
    private func safeContents(of url: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
    }
    
    /// Recursively mark everything under a URL as “don’t back up” (models are huge)
    private func excludeFromBackupRecursively(_ url: URL) {
        var urls = [url]
        if let kids = try? FileManager.default.subpathsOfDirectory(atPath: url.path) {
            urls += kids.map { url.appendingPathComponent($0) }
        }
        for u in urls {
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var m = u
            try? m.setResourceValues(values)
        }
    }
    
    /// Core logic:
    /// 1. If App Support doesn’t have the models yet, move them from Caches.
    /// 2. Replace the Caches folder with a symlink → App Support.
    /// 3. Mark the files so they don’t sync to iCloud.
    ///
    /// Result: WhisperKit still thinks it’s using Caches, but models are permanent + safe.
    func ensurePersistentModel() throws {
        let fm = FileManager.default
        let appSup = try appSupportURL()
        let cache  = cacheURL()
        
        // First-time run: move files from Caches → App Support
        if safeContents(of: appSup).isEmpty, fm.fileExists(atPath: cache.path) {
            try fm.createDirectory(at: appSup, withIntermediateDirectories: true)
            for item in safeContents(of: cache) {
                let dest = appSup.appendingPathComponent(item.lastPathComponent)
                if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
                try fm.moveItem(at: item, to: dest)
            }
        }
        
        // Always ensure Caches → symlink → App Support
        try replaceWithSymlink(from: cache, to: appSup)
        
        // Make sure models never hit iCloud
        excludeFromBackupRecursively(appSup)
    }
}
