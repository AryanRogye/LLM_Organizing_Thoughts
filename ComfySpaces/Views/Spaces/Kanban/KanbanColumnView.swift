//
//  KanbanColumnView.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

struct DraggableKanbanItem: Transferable, Identifiable, Hashable, Codable {
    let id: UUID
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}

struct KanbanColumnView: View {
    let column: KanbanColumn
    let items: [KanbanItem]
    let onDelete: (UUID) -> Void
    let onMoveHere: (UUID) -> Void
    let onDeleteColumn: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            header
            
            // Cards list (no internal scroll; outer board scrolls vertically)
            cardsList
        }
        .frame(width: 300)
        .contentShape(Rectangle())
        .dropDestination(for: DraggableKanbanItem.self) { items, _ in
            // Move first dragged item into this column's status
            if let first = items.first { onMoveHere(first.id) }
            return true
        } isTargeted: { hovering in
            // Optional visual feedback could be added here
        }
        .animation(.snappy, value: items)
    }
    
    private var cardsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.body).fontWeight(.semibold)
                    if !item.notes.isEmpty {
                        Text(item.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 8) {
                        Button("Move here") { onMoveHere(item.id) }
                        Button(role: .destructive) { onDelete(item.id) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .buttonStyle(.glass)
                    .font(.caption)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14))
                .draggable(DraggableKanbanItem(id: item.id)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title).font(.body).fontWeight(.semibold)
                        if !item.notes.isEmpty {
                            Text(item.notes).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }
    
    private var header: some View {
        HStack(alignment: .center) {
            Text(column.name)
                .font(.headline)
            Spacer()
            Text("\(items.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Menu {
                Button(role: .destructive) { onDeleteColumn() } label: {
                    Label("Delete Column", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(8)
                    .contentShape(Rectangle())
                    .background(.thinMaterial, in: .rect(cornerRadius: 8))
                    .accessibilityLabel("Column options")
            }
            .controlSize(.large)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

