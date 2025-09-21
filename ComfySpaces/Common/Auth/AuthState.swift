//
//  AuthState.swift
//  LLM_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/18/25.
//

import Combine
import Foundation

final class AuthState: ObservableObject {
    
    /// Load Simple Defaults From Defaults If User Wants Auth State Or Not
    enum Keys {
        static let shouldShowAuth  = "shouldShowAuth"
    }
    
    
    /// Defaults
    /// I do this because in init we can inject different settings
    /// and its nicer to test with
    private var defaults: UserDefaults
    
    @Published var isDoneInitializing: Bool = false
    @Published var shouldShowAuth : Bool {
        didSet {
            defaults.set(shouldShowAuth, forKey: Keys.shouldShowAuth)
        }
    }
    
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        
        AuthState.registerDefaults(in: defaults)
        
        self.shouldShowAuth = defaults.bool(forKey: Keys.shouldShowAuth)
        self.isDoneInitializing = true
    }
}

extension AuthState {
    public static func registerDefaults(in defaults: UserDefaults = .standard) {
        registerShouldShowAuth(defaults)
    }
    private static func registerShouldShowAuth(_ defaults: UserDefaults) {
        defaults.register(defaults: [Keys.shouldShowAuth: false])
    }
}

