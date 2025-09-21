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
        You are a sanitizer. Remove or replace profanity, sexual, or unsafe content \
        from transcripts while keeping the general meaning.
        Return only the cleaned text.
        """
    )
    
    func clean(_ text: String) async throws -> String {
        let res = try await session.respond(generating: CleanResult.self) {
            Prompt {
                "Transcript:\n\(text)"
                "Return only the cleaned transcript via `cleaned`."
            }
        }
        return res.content.cleaned
    }
}
