//
//  RecordingRow.swift
//  Offline_Organizing_Thoughts
//
//  Split by Aryan/Codex on 9/21/25.
//

import SwiftUI

struct RecordingRow: View {
    var item: RecordingItem
    var playView: (URL) -> AudioView
    var deleteAction: () -> Void

    var body: some View {
        RecordingRowHeader(
            emoji: item.emoji,
            title: item.url.deletingPathExtension().lastPathComponent,
            subtitle: "\(item.date.formatted(date: .abbreviated, time: .standard)) · \(formatTime(item.duration))",
            playView: { playView(item.url) },
            deleteAction: deleteAction
        )
    }
}
