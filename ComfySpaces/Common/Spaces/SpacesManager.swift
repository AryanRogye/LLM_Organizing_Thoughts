//
//  SpacesManager.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import Foundation
import Combine

@MainActor
class SpacesManager: ObservableObject {
    
    @Published var showingSpaces: Bool = false
    
    @Published var spaces : [Space] = []
    @Published var selectedSpace : Space?
    
    @Published var showingAddColumnSheet = false
    @Published var showingAddItemSheet = false

    private var cancellables = Set<AnyCancellable>()
    
    init() {
        load()
        // auto-save on changes (debounced so you don’t thrash disk)
        $spaces
            .dropFirst()
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.save()
            }
            .store(in: &cancellables)
    }
    
    func addProject(named name: String) {
        let project = Space(name: name)
        spaces.append(project)
    }
    
    func deleteProject(_ spacesID: UUID) {
        if let idx = spaces.firstIndex(where: { $0.id == spacesID }) {
            spaces.remove(at: idx)
            // Clear selection if we deleted the selected space
            if selectedSpace?.id == spacesID {
                selectedSpace = nil
                showingSpaces = false
            }
        }
    }
    
    // MARK: - Item Management (on selected project)
    
    func addItem(title: String, notes: String = "") {
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
    
    func deleteItem(_ itemID: UUID) {
        guard let selID = selectedSpace?.id, let pIdx = spaces.firstIndex(where: { $0.id == selID }) else { return }
        if let iIdx = spaces[pIdx].items.firstIndex(where: { $0.id == itemID }) {
            spaces[pIdx].items.remove(at: iIdx)
            selectedSpace = spaces[pIdx]
            save()
        }
    }
    
    func moveItem(_ itemID: UUID, toColumn columnID: UUID) {
        guard let selID = selectedSpace?.id, let pIdx = spaces.firstIndex(where: { $0.id == selID }) else { return }
        if let iIdx = spaces[pIdx].items.firstIndex(where: { $0.id == itemID }) {
            spaces[pIdx].items[iIdx].columnID = columnID
            selectedSpace = spaces[pIdx]
            save()
        }
    }
    
    // MARK: - Column Management (on selected project)
    func addColumn(named name: String) {
        guard let selID = selectedSpace?.id, let pIdx = spaces.firstIndex(where: { $0.id == selID }) else { return }
        spaces[pIdx].columns.append(KanbanColumn(name: name))
        selectedSpace = spaces[pIdx]
        save()
    }
    
    func renameColumn(_ columnID: UUID, to newName: String) {
        guard let selID = selectedSpace?.id, let pIdx = spaces.firstIndex(where: { $0.id == selID }) else { return }
        if let cIdx = spaces[pIdx].columns.firstIndex(where: { $0.id == columnID }) {
            spaces[pIdx].columns[cIdx].name = newName
            selectedSpace = spaces[pIdx]
            save()
        }
    }
    
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


private struct PersistedSpaces: Codable {
    var spaces: [Space]
}

extension SpacesManager {
    static var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("BoardStore.json")
    }
    
    func save() {
        let snapshot = PersistedSpaces(spaces: spaces)
        do {
            let data = try JSONEncoder().encode(snapshot)
            // ensure parent exists + exclude from iCloud
            try Self.ensureParentDir(for: Self.fileURL)
            try data.write(to: Self.fileURL, options: .atomic)
        } catch {
#if DEBUG
            print("Spaces save error:", error)
#endif
        }
    }
    
    func load() {
        do {
            guard FileManager.default.fileExists(atPath: Self.fileURL.path) else { return }
            let data = try Data(contentsOf: Self.fileURL)
            let decoded = try JSONDecoder().decode(PersistedSpaces.self, from: data)
            DispatchQueue.main.async {
                self.spaces = decoded.spaces
                // Keep selection pointing at the live instance from `spaces`
                if let selID = self.selectedSpace?.id,
                   let idx = self.spaces.firstIndex(where: { $0.id == selID }) {
                    self.selectedSpace = self.spaces[idx]
                }
            }
        } catch {
#if DEBUG
            print("Spaces load error:", error)
#endif
        }
    }
    
    private static func ensureParentDir(for url: URL) throws {
        let fm = FileManager.default
        let dir = url.deletingLastPathComponent()
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        var m = dir; try? m.setResourceValues(values)
    }
}
