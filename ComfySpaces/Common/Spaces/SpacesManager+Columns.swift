//
//  SpacesManager+Columns.swift
//  ComfySpaces
//
//  Created by Aryan Rogye on 9/21/25.
//

import Foundation
// ==============================================================
// Columns
// ==============================================================

// ==============================================================
// MARK: - Column Management (on selected project)
// ==============================================================
extension SpacesManager {
    // ==============================================================
    // MARK: - Add Column
    // ==============================================================
    func addColumn(named name: String) {
        guard let selID = selectedSpace?.id, let pIdx = spaces.firstIndex(where: { $0.id == selID }) else { return }
        spaces[pIdx].columns.append(KanbanColumn(name: name))
        selectedSpace = spaces[pIdx]
        save()
    }
    
    // ==============================================================
    // MARK: - Rename Column
    // ==============================================================
    func renameColumn(_ columnID: UUID, to newName: String) {
        guard let selID = selectedSpace?.id, let pIdx = spaces.firstIndex(where: { $0.id == selID }) else { return }
        if let cIdx = spaces[pIdx].columns.firstIndex(where: { $0.id == columnID }) {
            spaces[pIdx].columns[cIdx].name = newName
            selectedSpace = spaces[pIdx]
            save()
        }
    }
    
    // ==============================================================
    // MARK: - Delete Column
    // ==============================================================
    func deleteColumn(_ columnID: UUID, reassignTo fallbackColumnID: UUID? = nil) {
        guard let selID = selectedSpace?.id, let pIdx = spaces.firstIndex(where: { $0.id == selID }) else { return }
        // Determine destination for items currently in the deleted column
        let destinationID: UUID? = fallbackColumnID ?? spaces[pIdx].columns.first(where: { $0.id != columnID })?.id
        // Reassign or remove items
        if let dest = destinationID {
            for i in spaces[pIdx].items.indices {
                if spaces[pIdx].items[i].columnID == columnID {
                    spaces[pIdx].items[i].columnID = dest
                }
            }
        } else {
            spaces[pIdx].items.removeAll { $0.columnID == columnID }
        }
        // Remove the column itself
        spaces[pIdx].columns.removeAll { $0.id == columnID }
        selectedSpace = spaces[pIdx]
        save()
    }
}

