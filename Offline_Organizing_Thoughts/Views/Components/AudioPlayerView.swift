//
//  AudioPlayerView.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import SwiftUI
import Combine
import AVFoundation

final class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying: Bool = false
    private var player: AVAudioPlayer?
    
    init(url: URL) {
        super.init()
        do {
            self.player = try AVAudioPlayer(contentsOf: url)
            self.player?.delegate = self
            self.player?.prepareToPlay()
        } catch {
            print("Failed to initialize player: \(error)")
        }
    }
    
    func togglePlayback() {
        guard let player = player else { return }
        if isPlaying {
            player.stop()
            player.currentTime = 0
            isPlaying = false
        } else {
            let s = AVAudioSession.sharedInstance()
            try? s.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try? s.setActive(true)
            
            player.currentTime = 0
            player.play()
            isPlaying = true
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            player.currentTime = 0
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
        if let error = error {
            print("Audio player decode error: \(error)")
        }
    }
}

struct AudioView: View {
    @StateObject private var playerManager: AudioPlayerManager
    
    init(url: URL) {
        self._playerManager = StateObject(wrappedValue: AudioPlayerManager(url: url))
    }
    
    var image: String {
        playerManager.isPlaying ? "pause.fill" : "play.fill"
    }
    
    var body: some View {
        Button(action: {
            playerManager.togglePlayback()
        }) {
            Image(systemName: image)
                .resizable()
                .frame(width: 24, height: 24)
                .padding(6)
        }
    }
}
