//
//  SpacesList.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import SwiftUI

struct SpacesList: View {
    
    @EnvironmentObject var spacesManager: SpacesManager
    @State private var isShowingDeleteConfirm: Bool = false
    @State private var pendingDeleteSpaceID: UUID? = nil
    
    var body: some View {
        if spacesManager.spaces.isEmpty {
            VStack(spacing: 12) {
                Text("No Spaces yet")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(spacesManager.spaces) { space in
                    SpaceRow(space: space)
                        .modifier(GlassCard())
                        .padding(.horizontal, 16)
                        .contextMenu {
                            Button(role: .destructive) {
                                pendingDeleteSpaceID = space.id
                                isShowingDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .onTapGesture {
                            spacesManager.selectedSpace = space
                            spacesManager.showingSpaces = true
                        }
                }
            }
            .padding(.vertical, 8)
            .animation(.snappy, value: spacesManager.spaces)
            .alert("Delete this space?", isPresented: $isShowingDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    if let id = pendingDeleteSpaceID {
                        withAnimation {
                            spacesManager.deleteSpace(id)
                        }
                    }
                    pendingDeleteSpaceID = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingDeleteSpaceID = nil
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
}

private struct SpaceRow: View {
    let space: Space
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(space.name.isEmpty ? "Untitled Space" : space.name)
                    .font(.headline)
                HStack(spacing: 10) {
                    Label("\(space.columns.count) columns", systemImage: "square.grid.2x2")
                    Label("\(space.items.count) items", systemImage: "circle.grid.3x3")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}
