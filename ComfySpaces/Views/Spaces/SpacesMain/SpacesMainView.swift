//
//  aSpacesMainView.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct SpacesMainView: View {
    
    @Binding var space: Space
    
    @EnvironmentObject var spacesManager : SpacesManager
    
    @State private var searchText: String = ""
    
    @State private var newItemTitle = ""
    @State private var newColumnTitle = ""
    
    private func items(for column: KanbanColumn) -> [KanbanItem] {
        let all = (space.items).filter { $0.columnID == column.id }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return all }
        return all.filter { item in
            item.title.localizedCaseInsensitiveContains(q) || item.notes.localizedCaseInsensitiveContains(q)
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            KanbanCanvasView(
                columns: space.columns,
                itemsProvider: { column in items(for: column) },
                onDelete: { id in withAnimation(.snappy) { spacesManager.deleteItem(id) } },
                onMove: { id, toColumn in withAnimation(.snappy) { spacesManager.moveItem(id, toColumn: toColumn) } },
                onDeleteColumn: { columnID in withAnimation(.snappy) { spacesManager.deleteColumn(columnID) } }
            )
        }
        .animation(.snappy, value: spacesManager.selectedSpace?.items)
        .searchable(text: $searchText, prompt: "Search items")
        // MARK: - Sheet For Add Item
        .sheet(isPresented: $spacesManager.showingAddItemSheet) {
            sheetPage(
                title: "Add Item",
                text: $newItemTitle,
                cancel: $spacesManager.showingAddItemSheet,
                isAddDisabled: { text in
                    text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || spacesManager.selectedSpace == nil
                }
            ) {
                let title = newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty else { return }
                withAnimation(.snappy) { spacesManager.addItem(title: title) }
                newItemTitle = ""
                spacesManager.showingAddItemSheet = false
            }
        }
        // MARK: - Sheet For Add Column
        .sheet(isPresented: $spacesManager.showingAddColumnSheet) {
            sheetPage(
                title: "Add Column",
                text: $newColumnTitle,
                cancel: $spacesManager.showingAddColumnSheet,
                isAddDisabled: { text in
                    text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || spacesManager.selectedSpace == nil
                }
            ) {
                var title = newColumnTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                if title.isEmpty { title = "New Column" }
                spacesManager.addColumn(named: title)
                newColumnTitle = ""
                spacesManager.showingAddColumnSheet = false
            }
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .padding()
    }
    
    @ViewBuilder
    private func sheetPage(
        title: String,
        text: Binding<String>,
        cancel: Binding<Bool>,
        isAddDisabled: @escaping (String) -> Bool,
        submit: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            Text(title).font(.headline)
            TextField("Title", text: text)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit { submit() }
            HStack(spacing: 12) {
                Button("Cancel", role: .cancel) { cancel.wrappedValue = false }
                Button("Add") {
                    submit()
                }
                .buttonStyle(.glassProminent)
                .disabled(isAddDisabled(text.wrappedValue))
            }
            Spacer()
        }
        .padding()
    }
}
