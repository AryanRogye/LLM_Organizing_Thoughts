//
//  RecordingRowHeader.swift
//  Offline_Organizing_Thoughts
//
//  Split by Aryan/Codex on 9/21/25.
//

import SwiftUI

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
            // RowMenu could go here if needed later
        }
    }
}

