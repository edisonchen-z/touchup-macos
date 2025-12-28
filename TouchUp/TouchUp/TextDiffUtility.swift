//
//  TextDiffUtility.swift
//  TouchUp
//
//  Created by Edison Chen on 12/28/25.
//

import Foundation
import SwiftUI

/// Utility for computing word-level diffs between two text strings
struct TextDiffUtility {
    
    enum ChangeType {
        case unchanged
        case added
        case modified
        case deleted
    }
    
    struct WordChange {
        let word: String
        let type: ChangeType
    }
    
    /// Computes word-level differences between original and refined text
    /// Returns an array of WordChange objects for the refined text
    static func computeWordDiff(original: String, refined: String) -> [WordChange] {
        let originalWords = tokenize(original)
        let refinedWords = tokenize(refined)
        
        // Use LCS-based diff algorithm
        let changes = computeLCS(original: originalWords, refined: refinedWords)
        
        return changes
    }
    
    /// Tokenizes text into words while preserving whitespace information
    private static func tokenize(_ text: String) -> [String] {
        var words: [String] = []
        var currentWord = ""
        
        for char in text {
            if char.isWhitespace || char.isPunctuation {
                if !currentWord.isEmpty {
                    words.append(currentWord)
                    currentWord = ""
                }
                if !char.isWhitespace || (words.last != " ") {
                    words.append(String(char))
                }
            } else {
                currentWord.append(char)
            }
        }
        
        if !currentWord.isEmpty {
            words.append(currentWord)
        }
        
        return words
    }
    
    /// Simple LCS-based diff algorithm
    private static func computeLCS(original: [String], refined: [String]) -> [WordChange] {
        let m = original.count
        let n = refined.count
        
        // Build LCS table
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 1...m {
            for j in 1...n {
                if original[i-1] == refined[j-1] {
                    dp[i][j] = dp[i-1][j-1] + 1
                } else {
                    dp[i][j] = max(dp[i-1][j], dp[i][j-1])
                }
            }
        }
        
        // Backtrack to find changes
        var result: [WordChange] = []
        var i = m
        var j = n
        
        while i > 0 || j > 0 {
            if i > 0 && j > 0 && original[i-1] == refined[j-1] {
                result.insert(WordChange(word: refined[j-1], type: .unchanged), at: 0)
                i -= 1
                j -= 1
            } else if j > 0 && (i == 0 || dp[i][j-1] >= dp[i-1][j]) {
                result.insert(WordChange(word: refined[j-1], type: .added), at: 0)
                j -= 1
            } else if i > 0 {
                i -= 1
            }
        }
        
        return result
    }
    
    /// Creates an AttributedString with highlighted changes for the refined text
    static func createHighlightedText(changes: [WordChange]) -> AttributedString {
        var attributed = AttributedString()
        
        for change in changes {
            var wordString = AttributedString(change.word)
            
            switch change.type {
            case .unchanged:
                // No special styling
                break
            case .added, .modified:
                // Subtle green background for additions/modifications
                wordString.backgroundColor = Color.green.opacity(0.2)
                wordString.font = .system(.title3, weight: .semibold)
            case .deleted:
                // Not shown in refined text
                break
            }
            
            attributed.append(wordString)
        }
        
        return attributed
    }
}
