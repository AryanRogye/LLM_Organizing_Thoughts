//
//  RecordingList.swift
//  Offline_Organizing_Thoughts
//
//  Split by Aryan/Codex on 9/21/25.
//

import SwiftUI

enum RecordingLimitMode {
    case none
    case count(Int)
}

struct RecordingList: View {
    var limit: RecordingLimitMode = .none
    @Binding var recordings: [RecordingItem]
    var playView: (URL) -> AudioView
    var deleteRecording: ((IndexSet) -> ())?
    
    /// PARAMETERS:
    /// FIRST EMOJI PICKED
    /// SECOND EMOJI PICKED
    /// FINAL DECISION IT MADE
    var onEmojiGenerate: ((
        RecordingItem,
        @escaping (String) -> Void,
        @escaping (String) -> Void,
        @escaping (String) -> Void,
        @escaping (String) -> Void,
        @escaping (String) -> Void
    ) async -> Void)?

    private var displayedRecordings: [RecordingItem] {
        switch limit {
        case .none:
            return recordings
        case .count(let n):
            guard n >= 0 else { return [] }
            return Array(recordings.prefix(n))
        }
    }

    @State private var selectedMoreItem: RecordingItem? = nil

    var body: some View {
        ForEach(displayedRecordings) { item in
            RecordingRow(
                item: item,
                playView: { url in playView(url) },
                deleteAction: {
                    if let idx = recordings.firstIndex(of: item) {
                        deleteRecording?(IndexSet(integer: idx))
                    }
                }
            )
            .swipeActions(edge: .trailing) {
                Button { selectedMoreItem = item } label: {
                    Label("more", systemImage: "ellipsis")
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    if let idx = recordings.firstIndex(of: item) {
                        deleteRecording?(IndexSet(integer: idx))
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .onDelete(perform: deleteRecording)
        .sheet(item: $selectedMoreItem) { item in
            MoreOptionsSheet(
                item: item,
                onClose: { selectedMoreItem = nil },
                onEmojiGenerate: { rec, transcription, emoji_one, emoji_two, final_emoji, transcript_duration in
                    await onEmojiGenerate?(rec, transcription, emoji_one, emoji_two, final_emoji, transcript_duration)
                },
                onDelete: { rec in
                    if let idx = recordings.firstIndex(of: rec) {
                        deleteRecording?(IndexSet(integer: idx))
                    }
                    selectedMoreItem = nil
                }
            )
            .presentationDetents([.medium, .large])
            .presentationContentInteraction(.scrolls)
        }
    }
}
