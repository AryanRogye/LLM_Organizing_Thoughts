//
//  KanbanCanvasView.swift
//  ComfySpaces
//
//  Created by Aryan Rogye on 9/21/25.
//

import SwiftUI

struct KanbanCanvasView: View {
    let columns: [KanbanColumn]
    let itemsProvider: (KanbanColumn) -> [KanbanItem]
    let onDelete: (UUID) -> Void
    let onMove: (UUID, UUID) -> Void // (itemID, toColumnID)
    let onDeleteColumn: (UUID) -> Void
    
    @State private var zoomScale: CGFloat = 1.0
    @State private var steadyZoomScale: CGFloat = 1.0
    @State private var isZooming: Bool = false
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView([.vertical, .horizontal], showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(columns) { column in
                            KanbanColumnView(
                                column: column,
                                items: itemsProvider(column),
                                onDelete: { id in withAnimation(.snappy) { onDelete(id) } },
                                onMoveHere: { id in withAnimation(.snappy) { onMove(id, column.id) } },
                                onDeleteColumn: { withAnimation(.snappy) { onDeleteColumn(column.id) } }
                            )
                            .glassEffect(.regular, in: .rect(cornerRadius: 18))
                        }
                    }
                }
                .scaleEffect(zoomScale, anchor: .topLeading)
                .animation(.snappy, value: zoomScale)
                .frame(minWidth: proxy.size.width, minHeight: proxy.size.height, alignment: .topLeading)
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                MagnificationGesture()
                    .onChanged { value in
                        isZooming = true
                        let proposed = steadyZoomScale * value
                        zoomScale = min(max(proposed, 0.5), 3.0)
                    }
                    .onEnded { _ in
                        steadyZoomScale = zoomScale
                        isZooming = false
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        withAnimation(.snappy) {
                            if abs(zoomScale - 1.0) < 0.01 {
                                zoomScale = 2.0
                            } else {
                                zoomScale = 1.0
                            }
                            steadyZoomScale = zoomScale
                        }
                    }
            )
            .clipped()
        }
    }
}

