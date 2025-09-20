//
//  RootView.swift
//  LLM_Organizing_Thoughts
//
//  Created by Assistant on 9/18/25.
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject var appState : AppState

    var body: some View {
        TabView(selection: $appState.tab) {
            ForEach(Tabs.allCases, id: \.self) { tab in
                tab.view
                    .tabItem {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .toolbarBackground(.automatic, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    @Previewable @StateObject var appState      : AppState  = AppState()
    @Previewable @StateObject var authState     : AuthState = AuthState()
    @Previewable @StateObject var audioManager  : AudioRecorderManager = AudioRecorderManager()
    
    NavigationStack {
        RootView()
            .environmentObject(appState)
            .environmentObject(authState)
            .environmentObject(audioManager)
    }
}
