//
//  SpacesHomeView.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import SwiftUI

struct SpacesHomeView: View {
    
    @EnvironmentObject var spacesManager: SpacesManager
    @State private var newProjectName: String = ""
    
    var body: some View {
        ScrollView {
            createSpaces
            
            SpacesList()
        }
    }
    
    
    // MARK: - Create Project
    private var createSpaces: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create a Space")
                .font(.headline)
            HStack(spacing: 10) {
                TextField("New Space Name", text: $newProjectName)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .onSubmit(addSpace)
                Button(action: {
                    addSpace()
                }) {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.glassProminent)
            }
        }
        .modifier(GlassCard())
        .padding(16)
    }
    
    private func addSpace() {
        let name = newProjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        spacesManager.addSpace(named: name)
        newProjectName = ""
    }
}
