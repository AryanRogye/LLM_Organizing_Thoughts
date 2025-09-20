//
//  AudioEngineRecorder.swift
//  AudioRecorder
//
//  Created by Aryan Rogye on 9/16/25.
//

import Foundation
import AVFoundation

final class PCMFileWriter {
    private let queue = DispatchQueue(label: "pcm-writer-queue")
    private var pending: [AVAudioPCMBuffer] = []
    private let lock = NSLock()
    private let file: AVAudioFile
    
    init(file: AVAudioFile) {
        self.file = file
    }
    
    func enqueue(_ buf: AVAudioPCMBuffer) {
        lock.lock(); pending.append(buf); lock.unlock()
        queue.async { [weak self] in
            guard let self = self else { return }
            while true {
                self.lock.lock()
                guard !self.pending.isEmpty else { self.lock.unlock(); break }
                let b = self.pending.removeFirst()
                self.lock.unlock()
                try? self.file.write(from: b)
            }
        }
    }
    
    func finish() {
        queue.sync { }
    }
}

final class VoiceProcessingRecorder {
    private let engine = AVAudioEngine()
    private var file: AVAudioFile?
    private var outURL: URL?
    private var tapInstalled: Bool = false
    private var writer: PCMFileWriter?
    
    var onLevel: ((Float) -> Void)?
    
    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
        
        var granted = false
        let sema = DispatchSemaphore(value: 0)
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { ok in
                granted = ok
                sema.signal()
            }
        } else {
            session.requestRecordPermission { ok in
                granted = ok
                sema.signal()
            }
        }
        sema.wait()
        guard granted else {
            throw NSError(domain: "Audio", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mic permission denied"])
        }
        
        try session.setActive(true)
        
        let inNode = engine.inputNode
        let inFmt = inNode.inputFormat(forBus: 0)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let filename = "Recording-\(formatter.string(from: Date())).caf"
        let docs = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let url = docs.appendingPathComponent(filename)
        outURL = url
        let f = try AVAudioFile(forWriting: url, settings: inFmt.settings)
        self.file = f
        let writer = PCMFileWriter(file: f)
        self.writer = writer
        
        inNode.installTap(onBus: 0, bufferSize: 4096, format: inFmt) { [weak self] buf, _ in
            guard let self = self, let writer = self.writer else { return }
            guard buf.frameLength > 0 else { return }
            
            guard let copy = AVAudioPCMBuffer(pcmFormat: inFmt, frameCapacity: buf.frameLength) else { return }
            copy.frameLength = buf.frameLength
            
            if let srcs = buf.floatChannelData, let dsts = copy.floatChannelData {
                for ch in 0..<Int(inFmt.channelCount) {
                    memcpy(dsts[ch], srcs[ch], Int(buf.frameLength) * MemoryLayout<Float>.size)
                }
            } else {
                let byteCount = Int(buf.frameLength) * Int(inFmt.streamDescription.pointee.mBytesPerFrame)
                if let src = buf.audioBufferList.pointee.mBuffers.mData, let dst = copy.audioBufferList.pointee.mBuffers.mData {
                    memcpy(dst, src, byteCount)
                }
            }
            
            if let ch = buf.floatChannelData?[0] {
                let n = Int(buf.frameLength)
                if n > 0 {
                    var sum: Float = 0
                    var i = 0
                    while i < n {
                        let v = ch[i]
                        sum += v * v
                        i += 2
                    }
                    let mean = sum / Float(max(n / 2, 1))
                    let rms = sqrtf(mean)
                    let level = min(max(rms * 3.0, 0), 1)
                    if let cb = self.onLevel {
                        DispatchQueue.main.async { cb(level) }
                    }
                }
            }
            
            writer.enqueue(copy)
        }
        
        tapInstalled = true
        try engine.start()
    }
    
    func stop() -> URL? {
        if tapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        if engine.isRunning {
            engine.stop()
        }
        
        writer?.finish()
        writer = nil
        file = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
        return outURL
    }
}
