//
//  EmojiPicker.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import FoundationModels

@Generable
struct EmojiResult: Equatable {
    @Guide(.anyOf([
        "😀","😂","🤣","🥲","😊","😍","😘","😎","🤓","😇","🥰",
        "😅","😭","😢","😡","🤬","🤯","😱","😨","😴","🥱","🤔",
        "🙃","🫠","🫨","😏","😤","😳","🤡","💀","☠️","👻","👽",
        "🔥","💧","🌊","🌪️","❄️","🌈","☀️","🌙","⭐️","⚡️",
        "🎉","🎊","🎶","🎵","🎧","🎂","🍕","🍔","🍟","🍎",
        "❤️","🧡","💛","💚","💙","💜","🖤","🤍","💔","❣️",
        "💯","✅","❌","⚠️","🔒","🔓","📱","💻","🧠","🤖"
    ]))
    let emoji: String
}

protocol EmojiPickerProviding {
    func pick(from transcript: String) async throws -> String
}

final class EmojiPickerService: EmojiPickerProviding {
    private let session = LanguageModelSession(
        instructions: """
        You are an emoji selector. Given a transcript, return exactly one emoji \
        that best represents the overall vibe (mood or reaction). No text.
        """
    )
    
    func pick(from transcript: String) async throws -> String {
        
        do {
            let cleaned = try await Cleaner.shared.clean(transcript)
            
            let res = try await session.respond(
                generating: EmojiResult.self,
                options: .init(sampling: .greedy) // deterministic
            ) {
                Prompt {
                    "Transcript:\n\(cleaned)\n"
                    "Return only one emoji via the `emoji` field."
                }
            }
            return res.content.emoji
        } catch {
            return "🤔"
        }
    }
}
