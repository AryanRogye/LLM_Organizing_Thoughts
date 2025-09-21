//
//  SpacesDecider.swift
//  ComfySpaces
//
//  Created by Aryan Rogye on 9/20/25.
//

import FoundationModels

@Generable
struct SpaceGenerable {
    
}

@MainActor
final class SpacesDecider {
    private let session = LanguageModelSession()
    
    public func decide(from text: String) async {
        
    }
}
