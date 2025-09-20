//
//  ProjectsScreen.swift
//  LLM_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/18/25.
//

import SwiftUI
import Combine

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ProjectsScreen: View {
    
    @EnvironmentObject private var audioManager : AudioRecorderManager

    var body: some View {
        if audioManager.isRecording {
            RecordingScreen(
                level: audioManager.level,
                elapsed: audioManager.elapsed,
                stopAction: audioManager.tapRecord
            )
        } else {
            ZStack {
                VStack {
                    
                    topRow
                    ScrollView {
                        // Track scroll offset at the very top of the scroll view
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .named("projectsScroll")).minY)
                        }
                        .frame(height: 0)
                        
                        // Demo content to make the behavior visible
                        recentRecords
                    }
                    .onPreferenceChange(ScrollOffsetKey.self) { y in
                        // Negative y means we scrolled down
                        withAnimation(.snappy) {
                        }
                    }
                }
                
                recordButton
            }
            //        // Glassy, modern look for tab bar and navigation bar
            //        .toolbar(hideTabBar ? .hidden : .visible, for: .tabBar)
            //        .toolbarBackground(.automatic, for: .tabBar)
            //        .toolbarBackground(.visible, for: .tabBar)
            //        .toolbarBackground(.automatic, for: .navigationBar)
            //        .toolbarBackground(.visible, for: .navigationBar)
            .confirmationDialog(
                "Save recording?",
                isPresented: $audioManager.showSavePrompt,
                titleVisibility: .visible
            ) {
                Button("Save", role: .none) {
                    audioManager.confirmSave()
                }
                Button("Discard", role: .destructive) {
                    audioManager.discard()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Keep this recording or delete it?")
            }
        }
    }
    
    // MARK: - Top Row
    private var topRow: some View {
        HStack(alignment: .center) {
            VStack {
                Text("Voice Space")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 34, weight: .bold, design: .default))
                Text("Simple voice notes")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            
            NavigationLink(destination: SettingsScreen()) {
                Image(systemName: "gearshape")
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.glass)
            
        }
        .padding()
    }
    
    // MARK: - Recent Records
    private var recentRecords: some View {
        Section(header: HStack {
            Text("Recents")
                .font(.title2.weight(.semibold))
            Spacer()
        }.padding(.horizontal)) {
            RecordingList(
                limit: .count(3),
                recordings: $audioManager.recordings,
                playView: { url in
                    AudioView(url: url)
                }
            )
            .padding()
        }
    }
    
    // MARK: - Record Button
    private var recordButton: some View {
        VStack {
            Spacer()
            HStack{
                Spacer()
                
                Button(action: audioManager.tapRecord) {
                    Circle()
                        .frame(width: 70, height: 70)
                        .foregroundStyle(.red)
                        .overlay {
                            Circle()
                                .frame(width: 15, height: 15)
                                .foregroundStyle(.white)
                        }
                }
                .buttonStyle(.plain)
                .padding()
            }
        }
    }
}

#Preview {
    ProjectsScreen()
}
