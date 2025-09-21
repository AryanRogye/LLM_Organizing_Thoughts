//
//  AudioRecorderManager.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import Combine
import Foundation
import FoundationModels

@MainActor
final class AudioRecorderManager: ObservableObject {
    
    @Published var recordings: [RecordingItem] = []
    let fileManagerBridge = AppFileManager()
    
    @Published var level: Float = 0
    @Published var elapsed: TimeInterval = 0
    @Published var isRecording: Bool = false
    
    @Published var showSavePrompt = false
    @Published var pendingURL: URL? = nil
    
    @Published var transcribeReady: Bool = false
    
    private var timer: Timer?
    private var startDate: Date?
    
    let recorder = VoiceProcessingRecorder()
    let transcribe = TranscribeManager()
    
    let emojiPicker : EmojiPickerProviding = EmojiPickerService()
    
    init() {
        if let recordings = try? fileManagerBridge.loadRecordings() {
            self.recordings = recordings
        }
        Task {
            transcribeReady = await transcribe.prepareIfNeeded()
            Notify.shared.send(
                title: "Transcription Model",
                body: "\(transcribeReady ? "Ready" : "Not Ready")"
            )
        }
    }
    
    func tapRecord() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func stopRecording() {
        // stop and ask
        let url = recorder.stop()
        isRecording = false
        
        // stop meter/elapsed
        timer?.invalidate()
        timer = nil
        startDate = nil
        
        pendingURL = url
        showSavePrompt = (url != nil)
    }
    
    private func startRecording() {
        do {
            recorder.onLevel = { [weak self] v in self?.level = v }
            startDate = Date()
            elapsed = 0
            timer?.invalidate()
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self, let start = self.startDate else { return }
                    self.elapsed = Date().timeIntervalSince(start)
                }
            }
            try recorder.start()
            isRecording = true
        } catch {
            isRecording = false
        }
    }
    
    // already in Documents → just keep it
    func confirmSave() {
        
        if let pendingURL = pendingURL {
            if let item = try? fileManagerBridge.makeRecordingItem(from: pendingURL) {
                recordings.insert(item, at: 0)
            }
        }
        
        showSavePrompt = false
        pendingURL = nil
    }
    
    // Delete From Documents
    func discard() {
        if let url = pendingURL {
            try? FileManager.default.removeItem(at: url)
        }
        pendingURL = nil
        showSavePrompt = false
    }
    
    func deleteRecording(at index: Int) {
        guard recordings.indices.contains(index) else { return }
        let item = recordings[index]
        do {
            try fileManagerBridge.delete(item)
            recordings.remove(at: index)
        } catch {
            // Consider surfacing this via UI in the future
            print("Failed to delete recording: \(error)")
        }
    }
    
    func deleteRecording(at offsets: IndexSet) {
        // Delete from highest to lowest to maintain valid indices
        for i in offsets.sorted(by: >) {
            deleteRecording(at: i)
        }
    }
    
    func generateEmoji(
        _ item: RecordingItem,
        transcript: @escaping (String) -> Void,
        emoji_one: @escaping (String) -> Void,
        emoji_two: @escaping (String) -> Void,
        final_emoji: @escaping (String) -> Void,
        transcript_duration: @escaping (String) -> Void
    ) async {
        var t: Timer?
        do {
            // Measure actual wall-clock time to transcribe
            let start = Date()
            transcript_duration(formatTime(0))
            t = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                let elapsed = Date().timeIntervalSince(start)
                DispatchQueue.main.async {
                    transcript_duration(formatTime(elapsed))
                }
            }
            
            let transcription = try await transcribe.transcribe(url: item.url, progress: { _ in })
            
            // Stop timer and emit final elapsed time
            t?.invalidate(); t = nil
            let total = Date().timeIntervalSince(start)
            transcript_duration(formatTime(total))

            transcript(transcription)

            let emoji = try await emojiPicker.pick(
                from: transcription,
                excluding: item.emoji,
                emoji_one: emoji_one,
                emoji_two: emoji_two,
                final_emoji: final_emoji
            )

            print("Got Back Emoji: \(emoji)")

            var itemCopy = item
            itemCopy.emoji = emoji

            fileManagerBridge.setEmoji(for: itemCopy)

            if let idx = recordings.firstIndex(where: { $0.id == item.id }) {
                recordings[idx].emoji = emoji
            }
        } catch {
            t?.invalidate(); t = nil
            print("generateEmoji failed: \(error)")
        }
    }
}
