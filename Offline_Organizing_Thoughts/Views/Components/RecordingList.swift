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
    
    private var displayedRecordings: [RecordingItem] {
        switch limit {
        case .none:
            return recordings
        case .count(let n):
            guard n >= 0 else { return [] }
            return Array(recordings.prefix(n))
        }
    }
    
    var body: some View {
        ForEach(displayedRecordings) { item in
            RecordingRow(
                item: item,
                playView: {
                    url in playView(url)
                },
                renameAction: {
                    //                        rootVM.requestRename(item: item)
                },
                deleteAction: {
                    if let idx = recordings.firstIndex(of: item) {
                        //                            deleteRecording(at: IndexSet(integer: idx))
                    }
                }
            )
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    if let idx = recordings.firstIndex(of: item) {
                        //                            deleteRecording(at: IndexSet(integer: idx))
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
            //            .onDelete(perform: audioRM.deleteRecording)
    }
}

struct RecordingRow: View {
    var item: RecordingItem
    var playView: (URL) -> AudioView
    var renameAction: () -> Void
    var deleteAction: () -> Void
    
    var body: some View {
        RecordingRowHeader(
            title: item.url.deletingPathExtension().lastPathComponent,
            subtitle: "\(item.date.formatted(date: .abbreviated, time: .standard)) · \(formatTime(item.duration))",
            playView: { playView(item.url) },
            renameAction: renameAction,
            deleteAction: deleteAction
        )
    }
}

// MARK: - Subviews for RecordingRow
struct RecordingRowHeader: View {
    let title: String
    let subtitle: String
    var playView: () -> AudioView
    var renameAction: () -> Void
    var deleteAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
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

