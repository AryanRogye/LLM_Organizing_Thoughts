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
    private let spacesDecider = SpacesDecider()
    
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
    
    func addSpace(named name: String) {
        let space = Space(name: name)
        spaces.append(space)
    }
    
    func deleteSpace(_ spacesID: UUID) {
        if let idx = spaces.firstIndex(where: { $0.id == spacesID }) {
            spaces.remove(at: idx)
            // Clear selection if we deleted the selected space
            if selectedSpace?.id == spacesID {
                selectedSpace = nil
                showingSpaces = false
            }
        }
    }
}
