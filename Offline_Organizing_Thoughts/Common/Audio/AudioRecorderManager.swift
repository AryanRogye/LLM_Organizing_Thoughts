//
//  AudioRecorderManager.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import Combine
import Foundation

@MainActor
final class AudioRecorderManager: ObservableObject {
    
    @Published var recordings: [RecordingItem] = []
    let fileManagerBridge = AppFileManager()
    
    @Published var level: Float = 0
    @Published var elapsed: TimeInterval = 0
    @Published var isRecording: Bool = false
    
    @Published var showSavePrompt = false
    @Published var pendingURL: URL? = nil
    
    private var timer: Timer?
    private var startDate: Date?
    
    let recorder = VoiceProcessingRecorder()
    
    init() {
        if let recordings = try? fileManagerBridge.loadRecordings() {
            self.recordings = recordings
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
}
