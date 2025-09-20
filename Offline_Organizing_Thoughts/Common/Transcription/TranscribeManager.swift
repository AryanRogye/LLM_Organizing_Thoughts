//
//  TranscribeManager.swift
//  AudioRecorder
//
//  Created by Assistant on 9/17/25.
//

import Foundation
import WhisperKit
import AVFAudio

/// On-device Whisper transcription with progress & cancel.
final public class TranscribeManager {
    nonisolated(unsafe) private var cancelling = false
    
    private var pipe: WhisperKit?
    
    init() {
        
    }
    
    internal let whisperFolderName = "WhisperKit"
    
    // MARK: - Model init
    public func prepareIfNeeded() async -> Bool {
        if pipe != nil { return true }
        do {
            // let WhisperKit so it downloads if missing
            let config = WhisperKitConfig(model: "base.en")
            let tmpPipe = try await WhisperKit(config)
            
            // Persist the downloaded model & wire symlink
            try ensurePersistentModel()
            
            // Keep using the pipe; future launches will hit the symlinked path
            self.pipe = tmpPipe
            return true
        } catch {
            return false
        }
    }
    
    func normalizeToPCM16Mono16k(_ input: URL) throws -> URL {
        let output = input.deletingPathExtension().appendingPathExtension("wav")
        
        // Input file
        let inFile = try AVAudioFile(forReading: input)
        let inputFormat = inFile.processingFormat
        
        // Target format: PCM 16-bit, mono, 16 kHz
        let format = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                   sampleRate: 16_000,
                                   channels: 1,
                                   interleaved: true)!
        
        let outFile = try AVAudioFile(forWriting: output, settings: format.settings)
        guard let converter = AVAudioConverter(from: inputFormat, to: format) else {
            throw NSError(domain: "Conv", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAudioConverter"])
        }
        
        // We'll let the converter pull input via its input block. Avoid capturing any non-Sendable buffers.
        let inputFrameCapacity: AVAudioFrameCount = 4096
        var inputDone = false
        
        while true {
            // Create an output buffer for the target format
            guard let outBuffer = AVAudioPCMBuffer(pcmFormat: format,
                                                   frameCapacity: AVAudioFrameCount(format.sampleRate)) else {
                throw NSError(domain: "Conv", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to allocate output buffer"])
            }
            
            var error: NSError?
            let status = converter.convert(to: outBuffer, error: &error) { inNumPackets, outStatus in
                // If we've already signaled end-of-stream, return nil
                if inputDone {
                    outStatus.pointee = .endOfStream
                    return nil
                }
                // Allocate a fresh input buffer each time to avoid capturing a mutable buffer.
                let framesToRead = min(inNumPackets, inputFrameCapacity)
                guard let tempBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: framesToRead) else {
                    outStatus.pointee = .noDataNow
                    return nil
                }
                do {
                    try inFile.read(into: tempBuffer, frameCount: framesToRead)
                } catch {
                    // Consider any read error as end-of-stream for conversion purposes.
                    inputDone = true
                    outStatus.pointee = .endOfStream
                    return nil
                }
                if tempBuffer.frameLength == 0 {
                    inputDone = true
                    outStatus.pointee = .endOfStream
                    return nil
                }
                outStatus.pointee = .haveData
                return tempBuffer
            }
            
            if status == .error {
                throw error ?? NSError(domain: "Conv", code: -1, userInfo: [NSLocalizedDescriptionKey: "AVAudioConverter reported an error"])
            }
            
            if outBuffer.frameLength > 0 {
                try outFile.write(from: outBuffer)
            }
            
            if status == .endOfStream {
                break
            }
        }
        
        return output
    }
    
    // MARK: - Transcribe file
    /// Transcribe an audio file URL, reporting progress in [0,1].
    /// Throws CancellationError if you call `cancel()`.
    public func transcribe(url: URL, progress: @escaping (Double) -> Void) async throws -> String {
        guard await prepareIfNeeded() else { return "" }
        cancelling = false
        guard let pipe else { throw NSError(domain: "Transcribe", code: 1002, userInfo: [NSLocalizedDescriptionKey: "WhisperKit not ready"]) }
        
        // Progress callback (called from WhisperKit while decoding).
        // Return false to stop early (we do that if `cancel()` was called).
        let cb: TranscriptionCallback = { _ in
            // TODO: Map TranscriptionProgress to a 0...1 value when available from WhisperKit
            // For now, emit a heartbeat progress of 0 to keep UI responsive.
            progress(0)
            if self.cancelling { return false } // stop decoding
            return nil // continue
        }
        
        // Transcribe the file (WhisperKit handles WAV/MP3/M4A/FLAC, etc.)
        // Returns a TranscriptionResult? — grab its `text`.
        let results = try await pipe.transcribe(audioPath: url.path, callback: cb)
        if cancelling { throw CancellationError() }
        let combined = results.map { $0.text }.joined(separator: " ")
        print("RETURNING: \(combined)")
        return combined
    }
    
    // MARK: - Cancel
    public func cancel() {
        cancelling = true
    }
}
