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
    func pick(from transcript: String, excluding: String?) async throws -> String
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
    
    func pick(from transcript: String, excluding: String? = nil) async throws -> String {
        
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
            print("Primary emoji: \(chosen)")

            // If no exclusion requested, return the primary choice
            guard let excluding = excluding else { return chosen }

            // Request a second candidate that avoids both the excluded emoji and the primary choice
            func requestSecondCandidate() async throws -> String {
                let second = try await Self.session.respond(
                    generating: EmojiResult.self,
                    options: .init(sampling: .greedy)
                ) {
                    Prompt {
                        "Transcript:\n\(cleaned)\n"
                        "Return only one emoji via the `emoji` field."
                        "Do not choose the emoji: \(excluding)"
                        "Also do not choose the emoji: \(chosen)"
                        "Pick a different emoji than \(chosen)."
                    }
                }
                return second.content.emoji
            }

            var secondStr = try await requestSecondCandidate()

            // If the model still returns a duplicate (or the excluded), try one more time
            if secondStr == chosen || secondStr == excluding {
                secondStr = try await requestSecondCandidate()
            }

            print("Second candidate emoji: \(secondStr)")

            // If we still failed to produce a distinct second candidate, just return the primary
            guard secondStr != chosen, secondStr != excluding else {
                print("Could not obtain a distinct second candidate; returning primary.")
                return chosen
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

            print("Returning emoji: \(decider.content.emoji)")
            return decider.content.emoji
            
        } catch {
            return "🤔"
        }
    }
}

