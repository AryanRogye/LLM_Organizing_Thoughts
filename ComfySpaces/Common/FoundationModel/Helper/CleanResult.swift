//
//  CleanResult.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import Foundation
import FoundationModels

@Generable
struct CleanResult: Equatable {
    /// The transcript cleaned of profanity / sexual references
    let cleaned: String
}

actor Cleaner {
    static let shared = Cleaner()
    
    private let session = LanguageModelSession(
        instructions: """
        You are a text normalizer.
        Goal: return the input text unchanged unless it contains strongly offensive language.
        If offensive words appear, replace only the offending words with '***' while preserving meaning and punctuation.
        Do not add explanations, warnings, or extra text.
        Output must be the cleaned text only.
        
        Examples:
        - Input: "The quick brown fox jumps over the lazy dog."
          Output: "The quick brown fox jumps over the lazy dog."
        - Input: "You are a %#@!"
          Output: "You are a ***"
        """
    )
    
    func clean(_ text: String) async throws -> String {
        let res = try await session.respond(generating: CleanResult.self) {
            Prompt {
                "Text:\n\(text)"
                "Return only the cleaned transcript via `cleaned`."
            }
        }
        return res.content.cleaned
    }
}
