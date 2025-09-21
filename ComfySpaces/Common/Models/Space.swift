//
//  Space.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import Foundation

struct Space: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var columns: [KanbanColumn]
    var items: [KanbanItem]
    
    init(id: UUID = UUID(), name: String, columns: [KanbanColumn] = [KanbanColumn(name: "To Do"), KanbanColumn(name: "Doing"), KanbanColumn(name: "Done")], items: [KanbanItem] = []) {
        self.id = id
        self.name = name
        self.columns = columns
        self.items = items
    }
}

struct KanbanColumn: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

struct KanbanItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var notes: String
    var columnID: UUID
    
    init(id: UUID = UUID(), title: String, notes: String = "", columnID: UUID = UUID()) {
        self.id = id
        self.title = title
        self.notes = notes
        self.columnID = columnID
    }
}
