//
//  MoreOptionsSheet.swift
//  Offline_Organizing_Thoughts
//
//  Created by Codex on 9/21/25.
//

import SwiftUI

struct MoreOptionsSheet: View {
    let item: RecordingItem
    var onClose: () -> Void
    
    /// PARAMETERS:
    /// TRANSCRIPT
    /// FIRST EMOJI PICKED
    /// SECOND EMOJI PICKED
    /// FINAL DECISION IT MADE
    var onEmojiGenerate: (
        RecordingItem,
        @escaping (String) -> Void,
        @escaping (String) -> Void,
        @escaping (String) -> Void,
        @escaping (String) -> Void,
        @escaping (String) -> Void
    ) async -> Void
    
    @State private var transcription: String?
    @State private var first: String?
    @State private var second: String?
    @State private var final: String?
    @State private var transcriptDuration: String?
    @State private var isGenerating: Bool = false
    
    var onDelete: (RecordingItem) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                Divider()
                actionButtons
                EmojiResultsView(
                    transcriptDuration: transcriptDuration,
                    transcription: transcription,
                    first: first,
                    second: second,
                    final: final
                )
                Spacer(minLength: 8)
                closeButton
            }
            .padding(.bottom, 16)
            .padding(.top, 4)
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Derived data
    private var fileTitle: String {
        item.url.deletingPathExtension().lastPathComponent
    }
    
    private var subtitle: String {
        "\(item.date.formatted(date: .abbreviated, time: .standard)) · \(formatTime(item.duration))"
    }
    
    private var hasEmojiResults: Bool {
        transcription != nil || first != nil || second != nil || final != nil
    }
    
    // MARK: - Actions
    private func triggerEmojiGeneration() {
        transcription = nil
        first = nil
        second = nil
        final = nil
        transcriptDuration = nil

        isGenerating = true
        Task { @MainActor in
            await onEmojiGenerate(
                item,
                { e in transcription = e },
                { e in first = e },
                { e in second = e },
                { e in final = e },
                { d in transcriptDuration = d }
            )
            isGenerating = false
        }
    }
    
    // MARK: - Subviews
    private var header: some View {
        HStack(spacing: 12) {
            if let emoji = item.emoji, !emoji.isEmpty {
                Text(emoji).font(.title3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(fileTitle)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: triggerEmojiGeneration) {
                Label("Generate Emoji", systemImage: "face.smiling")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(isGenerating)

            if isGenerating {
                ProgressView("Generating…")
                    .frame(maxWidth: .infinity)
            }
            
            Button(role: .destructive) {
                onDelete(item)
            } label: {
                Label("Delete Recording", systemImage: "trash")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(.red)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(isGenerating)
        }
        .padding(.horizontal)
    }
    
    private var closeButton: some View {
        Button("Close", action: onClose)
            .buttonStyle(.bordered)
            .padding(.bottom, 12)
    }
}

struct EmojiResultsView: View {
    let transcriptDuration: String?
    let transcription: String?
    let first: String?
    let second: String?
    let final: String?

    private var hasResults: Bool {
        transcriptDuration != nil || transcription != nil || first != nil || second != nil || final != nil
    }

    var body: some View {
        Group {
            if hasResults {
                VStack(alignment: .leading, spacing: 10) {
                    if let transcriptDuration {
                        HStack(spacing: 8) {
                            Text("Transcript duration")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(transcriptDuration)
                                .font(.body)
                                .monospacedDigit()
                        }
                        Divider()
                    }
                    if let transcription {
                        HStack(spacing: 8) {
                            Text("Transcription")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(transcription)
                                .font(.body)
                                .multilineTextAlignment(.trailing)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .layoutPriority(1)
                        }
                        Divider()
                    }
                    if let first {
                        HStack(spacing: 8) {
                            Text("First pick")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(first)
                                .font(.title3)
                        }
                    }
                    if let second {
                        HStack(spacing: 8) {
                            Text("Second pick")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(second)
                                .font(.title3)
                        }
                    }
                    if let final {
                        Divider()
                        HStack(spacing: 8) {
                            Label("Final emoji", systemImage: "checkmark.seal.fill")
                                .labelStyle(.titleAndIcon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(final)
                                .font(.largeTitle)
                        }
                    }
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.15))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.default, value: hasResults)
        .animation(.default, value: transcriptDuration)
        .animation(.default, value: transcription)
        .animation(.default, value: first)
        .animation(.default, value: second)
        .animation(.default, value: final)
        .padding(.horizontal)
    }
}
