//
//  LibraryView.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import SwiftUI


struct LibraryView: View {
    
    @EnvironmentObject var audioManager : AudioRecorderManager
    
    var body: some View {
        VStack {
            List {
                RecordingList(
                    recordings: $audioManager.recordings,
                    playView: { url in
                        AudioView(url: url)
                    },
                    deleteRecording: { offsets in
                        audioManager.deleteRecording(at: offsets)
                    },
                    onEmojiGenerate: { recordingItem, transcript, emoji_one, emoji_two, final_emoji, transcript_duration in
                        await audioManager.generateEmoji(
                            recordingItem,
                            transcript: transcript,
                            emoji_one: emoji_one,
                            emoji_two: emoji_two,
                            final_emoji: final_emoji,
                            transcript_duration: transcript_duration
                        )
                    }
                )
            }
            .listStyle(.insetGrouped)
        }
    }
}
