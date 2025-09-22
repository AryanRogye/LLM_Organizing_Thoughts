//
//  EmojiPicker.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import FoundationModels


@Generable
struct EmojiResult: Equatable {
    let emoji: String
}

protocol EmojiPickerProviding {
    func pick(
        from transcript: String,
        excluding: String?,
        emoji_one: @escaping (String) -> Void,
        emoji_two: @escaping (String) -> Void,
        final_emoji: @escaping (String) -> Void
        
    ) async throws -> String
}

final class EmojiPickerService: EmojiPickerProviding {
    
    private static let session = LanguageModelSession(
        instructions: """
            You are an emoji selector. Return exactly one emoji from the provided schema. 
            Rules:
            Output only the emoji, no text.
            """
    )
    private static let emojiDecider = LanguageModelSession(
        instructions: """
            You Are A Emoji Decider. 
            
            Input: Transcribe, Emoji_1, Emoji_2
            
            Return exactly one emoji from the 2 emoji's
            that describes the tracript the best
            """
    )
    
    // Request a second candidate that avoids both the excluded emoji and the primary choic
    private func requestSecondCandidate(using text: String, excluding: String, and excluding_2: String) async throws -> String {
        let second = try await Self.session.respond(
            generating: EmojiResult.self,
            options: .init(sampling: .greedy)
        ) {
            Prompt {
                "Transcript:\n\(text)\n"
                "Return only one emoji via the `emoji` field."
                "Do not choose the emoji: \(excluding)"
                "Also do not choose the emoji: \(excluding_2)"
                "Pick a different emoji than \(excluding_2)."
            }
        }
        return second.content.emoji
    }
    
    func pick(
        from transcript: String,
        excluding: String? = nil,
        emoji_one: @escaping (String) -> Void,
        emoji_two: @escaping (String) -> Void,
        final_emoji: @escaping (String) -> Void
    ) async throws -> String {
        do {
            let cleaned = try await Cleaner.shared.clean(transcript)
            
            let res = try await Self.session.respond(
                generating: EmojiResult.self,
                options: .init(sampling: .greedy) // deterministic
            ) {
                Prompt {
                    "Transcript:\n\(cleaned)\n"
                    "Return only one emoji via the `emoji` field."
                }
            }
            
            let chosen = res.content.emoji
            

            emoji_one(chosen)
            
            // If no exclusion requested, return the primary choice
            guard let excluding = excluding else {
                emoji_two(chosen)
                final_emoji(chosen)
                return chosen
            }
            

            var secondStr = try await requestSecondCandidate(
                using: cleaned,
                excluding: chosen, and: excluding
            )
            

            // If the model still returns a duplicate (or the excluded), try one more time
            if secondStr == chosen || secondStr == excluding {
                secondStr = try await requestSecondCandidate(
                    using: cleaned,
                    excluding: chosen, and: excluding
                )
            }

            emoji_two(secondStr)

            // If we still failed to produce a distinct second candidate, just return the primary
            
            /// If The Second Chosen, and First Chosen Is Same
            if secondStr == chosen {
                /// AND
                /// Second Chosen and Excluding is the same
                if secondStr == excluding {
                    final_emoji(chosen)
                    return chosen
                }
            }
            

            let decider = try await Self.emojiDecider.respond(
                generating: EmojiResult.self,
                options: .init(sampling: .greedy)
            ) {
                Prompt {
                    "Transcript:\n\(cleaned)\n"
                    "Return only one emoji via the `emoji` field."
                    "Emoji_1: \(chosen)"
                    "Emoji_2: \(secondStr)"
                }
            }
            
            let final = decider.content.emoji

            final_emoji(final)
            return final
            
        } catch {
            return "🤔"
        }
    }
}

