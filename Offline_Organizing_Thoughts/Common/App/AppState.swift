//
//  AppState.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/18/25.
//

import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var tab : Tabs = .home
}
