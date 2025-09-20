//
//  SettingsScreen.swift
//  LLM_Organizing_Thoughts
//
//  Created by Assistant on 9/18/25.
//

import SwiftUI

struct SettingsScreen: View {
    
    @EnvironmentObject var authState : AuthState

    var body: some View {
        Form {
            Section("Lock") {
                Toggle("Allow Face-ID", isOn: $authState.shouldShowAuth)
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    @Previewable @StateObject var appState  : AppState  = AppState()
    @Previewable @StateObject var authState : AuthState = AuthState()
    
    NavigationStack {
        SettingsScreen()
            .environmentObject(appState)
            .environmentObject(authState)
    }
}
