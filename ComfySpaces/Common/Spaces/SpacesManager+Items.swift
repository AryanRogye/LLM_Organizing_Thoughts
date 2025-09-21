//
//  SpacesManager+Items.swift
//  ComfySpaces
//
//  Created by Aryan Rogye on 9/21/25.
//

import Foundation
// ==============================================================
// Items
// ==============================================================

// ==============================================================
// MARK: - Item Management (on selected project)
// ==============================================================
extension SpacesManager {
    // ==============================================================
    // MARK: - Add Item
    // ==============================================================
    public func addItem(title: String, notes: String = "") {
        guard let selID = selectedSpace?.id, let pIdx = spaces.firstIndex(where: { $0.id == selID }) else { return }
        let defaultColumnID = spaces[pIdx].columns.first?.id ?? {
            let col = KanbanColumn(name: "To Do")
            spaces[pIdx].columns.append(col)
            return col.id
        }()
        spaces[pIdx].items.append(KanbanItem(title: title, notes: notes, columnID: defaultColumnID))
        // Keep selectedSpace in sync with backing array
        selectedSpace = spaces[pIdx]
        save()
    }
    
    // ==============================================================
    // MARK: - Delete Item
    // ==============================================================
    public func deleteItem(_ itemID: UUID) {
        guard let selID = selectedSpace?.id, let pIdx = spaces.firstIndex(where: { $0.id == selID }) else { return }
        if let iIdx = spaces[pIdx].items.firstIndex(where: { $0.id == itemID }) {
            spaces[pIdx].items.remove(at: iIdx)
            selectedSpace = spaces[pIdx]
            save()
        }
    }
    
    // ==============================================================
    // MARK: - Move Item
    // ==============================================================
    public func moveItem(_ itemID: UUID, toColumn columnID: UUID) {
        guard let selID = selectedSpace?.id, let pIdx = spaces.firstIndex(where: { $0.id == selID }) else { return }
        if let iIdx = spaces[pIdx].items.firstIndex(where: { $0.id == itemID }) {
            spaces[pIdx].items[iIdx].columnID = columnID
            selectedSpace = spaces[pIdx]
            save()
        }
    }
}

