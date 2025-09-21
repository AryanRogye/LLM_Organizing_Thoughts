//
//  RecordingList.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
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
    var onEmojiGenerate: ((RecordingItem) -> Void)?
    
    private var displayedRecordings: [RecordingItem] {
        switch limit {
        case .none:
            return recordings
        case .count(let n):
            guard n >= 0 else { return [] }
            return Array(recordings.prefix(n))
        }
    }
    
    @State var selectedMoreItem: RecordingItem? = nil
    
    var body: some View {
        ForEach(displayedRecordings) { item in
            RecordingRow(
                item: item,
                playView: {
                    url in playView(url)
                },
                deleteAction: {
                    if let idx = recordings.firstIndex(of: item) {
                        deleteRecording?(IndexSet(integer: idx))
                    }
                },
                selectedItem: $selectedMoreItem
            )
            .swipeActions(edge: .trailing) {
                Button {
                    selectedMoreItem = item
                } label: {
                    Label("more", systemImage: "ellipsis")
                }
            }
            .swipeActions(edge: .trailing) {
                Button {
                    onEmojiGenerate?(item)
                } label: {
                    Label("Emoji", systemImage: "face.smiling")
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
    }
}

struct RecordingRow: View {
    var item: RecordingItem
    var playView: (URL) -> AudioView
    var deleteAction: () -> Void
    @Binding var selectedItem: RecordingItem?
    
    var body: some View {
        VStack(spacing: 0) {
            RecordingRowHeader(
                emoji: item.emoji,
                title: item.url.deletingPathExtension().lastPathComponent,
                subtitle: "\(item.date.formatted(date: .abbreviated, time: .standard)) · \(formatTime(item.duration))",
                playView: { playView(item.url) },
                deleteAction: deleteAction
            )
            if selectedItem == item {
                HStack {
                    Button(action: {
                        selectedItem = nil
                    }) {
                        Text("Close More Options")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 30)
                .border(Color(.secondarySystemBackground), width: 1)
            }
        }
    }
}

// MARK: - Subviews for RecordingRow
struct RecordingRowHeader: View {
    let emoji: String?
    let title: String
    let subtitle: String
    var playView: () -> AudioView
    var deleteAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if let emoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.title2)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            playView()
            //            RowMenu(renameAction: renameAction, deleteAction: deleteAction)
        }
    }
}

