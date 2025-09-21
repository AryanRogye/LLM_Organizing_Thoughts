//
//  SpacesView.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import SwiftUI

struct SpacesRootView: View {
    
    @EnvironmentObject var spacesManager : SpacesManager
    
    var body: some View {
        VStack {
            topRow
            if spacesManager.showingSpaces {
                SpacesMainRootView(
                    space: $spacesManager.selectedSpace
                )
            } else {
                SpacesHomeView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Top Row
    private var topRow: some View {
        HStack {
            Text("Your Spaces")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 34, weight: .bold, design: .default))

            if spacesManager.showingSpaces {
                
                Button {
                    spacesManager.showingAddColumnSheet = true
                } label: {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.glass)

                Button {
                    spacesManager.showingAddItemSheet = true
                } label: {
                    Image(systemName: "doc.badge.plus")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.glass)

                Button {
                    withAnimation(.snappy) { spacesManager.showingSpaces = false }
                } label: {
                    Image(systemName: "house")
                        .resizable()
                        .frame(width: 24, height: 24)
                    
                }
                .buttonStyle(.glass)
            } else {
                Button {
                    withAnimation(.snappy) { spacesManager.showingSpaces = true }
                } label: {
                    Image(systemName: "square.grid.3x3")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.glass)
            }
        }
        .padding()
    }
}

#Preview {
    
    @Previewable @StateObject var appState      : AppState  = AppState()
    @Previewable @StateObject var authState     : AuthState = AuthState()
    @Previewable @StateObject var audioManager  : AudioRecorderManager = AudioRecorderManager()
    @Previewable @StateObject var spacesManager  : SpacesManager        = SpacesManager()


    SpacesRootView()
        .environmentObject(appState)
        .environmentObject(authState)
        .environmentObject(audioManager)
        .environmentObject(spacesManager)
        .task {
#if DEBUG
            audioManager.recordings = audioManager.fileManagerBridge.loadMockRecordings()
#endif
        }
}
