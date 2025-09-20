//
//  Offline_Organizing_ThoughtsApp.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/18/25.
//

import SwiftUI

@main
struct Offline_Organizing_ThoughtsApp: App {
    
    @StateObject var appState       : AppState  = AppState()
    @StateObject var authState      : AuthState = AuthState()
    @StateObject var audioManager   : AudioRecorderManager = AudioRecorderManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if !authState.isDoneInitializing {
                    ProgressView()
                } else if authState.shouldShowAuth {
                    AuthView {
                        RootView()
                    }
                } else {
                    RootView()
                }
            }
        }
        .environmentObject(appState)
        .environmentObject(authState)
        .environmentObject(audioManager)
    }
}
