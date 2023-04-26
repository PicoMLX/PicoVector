//
//  TextSplitter.swift
//  VectorNest
//
//  Created by Ronald Mannak on 4/24/23.
//

import Foundation
import GPTEncoder

enum TextSplitterError: Error {
    case invalidChunkSize
}

/// Small sized chunks for better semantic search results, combine chunks to send to LLM for better results
/// Based on https://github.com/hwchase17/langchain
protocol TextSplitter {
    
    var lengthFunction: (String) -> Int { get }
    var text: String { get }
    var chunkSize: Int { get }
    var chunkOverlap: Int { get }
    
    func split() -> [String]
    func merge(splits: [String], separator: String) -> [String]
    func join(docs: [String], separator: String) -> String?
}

extension TextSplitter {
        
    /// Combine these smaller pieces into medium size chunks to send to the LLM.
    /// This function takes an array of text splits and a separator as input, and merges the splits into medium-sized chunks according to the specified chunk size, chunk overlap, and length functions defined in the conforming type. Great care is taken to minimize the number of occurrences where the merged text exceeds the specified chunk size, with a warning logged if this occurs. After merging, the final list of document chunks is returned.
    /// - Parameters:
    ///   - splits: <#splits description#>
    ///   - separator: <#separator description#>
    /// - Returns: <#description#>
    func merge(splits: [String], separator: String) -> [String] {
        let separatorLength = lengthFunction(separator)
        
        var docs: [String] = []
        var currentDoc: [String] = []
        var total = 0
        
        // Iterate through the provided text splits.
        for split in splits {
            
            // Check if adding the current split to the total length along with the separator would exceed the desired chunk size
            let length = lengthFunction(split)
            if total + length + (separatorLength * (currentDoc.count > 0 ? 1 : 0)) > chunkSize {
                if total > chunkSize {
                    print("Warning: Created a chunk of size \(total), which is longer than the specified \(chunkSize)")
                }
                if currentDoc.count > 0 {
                    // If the current document has content, append the joined document to the final list of documents.
                    let doc = join(docs: currentDoc, separator: separator)
                    if let doc = doc {
                        docs.append(doc)
                    }
                    
                    // Continue removing the first element of the current document until it doesn't exceed the specified chunk overlap or chunk size
                    while total > chunkOverlap || (total + length + (separatorLength * (currentDoc.count > 0 ? 1 : 0)) > chunkSize && total > 0) {
                        if !currentDoc.isEmpty {
                            total = total - lengthFunction(currentDoc[0]) + (separatorLength * (currentDoc.count > 1 ? 1 : 0))
                            currentDoc.removeFirst()
                        }
                    }
                }
            }
            
            // Add the current split to the current document and update the total length.
            currentDoc.append(split)
            total += length + (separatorLength * (currentDoc.count > 1 ? 1 : 0))
        }
        
        // After iterating through all splits, join any remaining elements in the current document and add it to the final list of documents
        if let doc = join(docs: currentDoc, separator: separator) {
            docs.append(doc)
        }
        
        return docs
    }

    
    /// This function takes an array of strings (`docs`) and a separator as input, joins the strings using the separator, and trims whitespace from the beginning and end of the resulting string. If the resulting string is empty, the function returns `nil`, otherwise it returns the joined and trimmed string
    /// - Parameters:
    ///   - docs: <#docs description#>
    ///   - separator: <#separator description#>
    /// - Returns: <#description#>
    func join(docs: [String], separator: String) -> String? {
        let text = docs.joined(separator: separator).trimmingCharacters(in: .whitespacesAndNewlines)

        if text.isEmpty {
            return nil
        } else {
            return text
        }
    }
}

