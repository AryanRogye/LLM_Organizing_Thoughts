//
//  AuthScreen.swift
//  LLM_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/18/25.
//

import SwiftUI
import LocalAuthentication

public struct AuthView<Content: View>: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isUnlocked: Bool = false
    @State private var didAutoPromptThisSession: Bool = false
    
    private let reason: String
    private let content: () -> Content
    
    public init(reason: String = "Unlock to access your content", @ViewBuilder content: @escaping () -> Content) {
        self.reason = reason
        self.content = content
    }
    
    public var body: some View {
        ZStack {
            if isUnlocked {
                content()
                    .transition(.opacity)
            } else {
                LockScreen(promptAction: authenticate)
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Prompt on first appearance per session
            if !didAutoPromptThisSession {
                didAutoPromptThisSession = true
                authenticate()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                // Re-lock when app goes to background
                isUnlocked = false
                didAutoPromptThisSession = false
            case .active:
                // Auto-prompt when returning to foreground if locked
                if !isUnlocked && !didAutoPromptThisSession {
                    didAutoPromptThisSession = true
                    authenticate()
                }
            default:
                break
            }
        }
    }
    
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        let policy: LAPolicy = .deviceOwnerAuthentication
        
        if context.canEvaluatePolicy(policy, error: &error) {
            context.evaluatePolicy(policy, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    withAnimation { self.isUnlocked = success }
                }
            }
        } else {
            // If device can't evaluate policy (no biometrics/passcode), allow access
            DispatchQueue.main.async {
                withAnimation { self.isUnlocked = true }
            }
        }
    }
}

private struct LockScreen: View {
    var promptAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 72))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.blue, .white)
                .shadow(radius: 4)
            
            Text("Locked")
                .font(.title2).bold()
            
            Text("Unlock with Face ID or your passcode to continue.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button(action: promptAction) {
                Label("Unlock", systemImage: "faceid")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.blue, in: .capsule)
                    .foregroundStyle(.white)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
