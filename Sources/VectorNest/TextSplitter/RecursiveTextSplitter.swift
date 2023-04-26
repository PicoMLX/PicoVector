//
//  RecursiveTextSplitter.swift
//  VectorNest
//
//  Created by Ronald Mannak on 4/25/23.
//

import Foundation
import GPTEncoder

public struct RecursiveTextSplitter: TextSplitter {   
    
    public let lengthFunction: (String) -> Int
    
    public let text: String
    
    /// Defaults to character count in LangChain
    public let chunkSize: Int
    
    /// Defaults to character count in LangChain
    public let chunkOverlap: Int
    public let separators: [String]
    
    public init(text: String, chunkSize: Int = 2_000, chunkOverlap: Int = 100, separators: [String] = ["\n\n", "\n", " ", ""], lengthFunction: ((String) -> Int)? = nil) throws {
        guard chunkSize > chunkOverlap else { throw TextSplitterError.invalidChunkSize }
        self.text = text
        self.chunkSize = chunkSize
        self.chunkOverlap = chunkOverlap
        self.separators = separators
        // lengthFunction defaults to counting characters, as in LangChain
        // to count tokens for ada002 and gpt3.5 and higher, use GPTEncoder().encoder.encode(text: string).count
        self.lengthFunction = lengthFunction ?? { $0.count } // Defaults to counting characters, as in LangChain
    }
    
    ///  Implementation of splitting text that looks at characters.
    ///  Recursively tries to split by different characters to find one that works.
    /// - Parameter text: <#text description#>
    /// - Returns: <#description#>
    ///
    public func split() -> [String] {
         return split(text: text)
    }
    
    private func split(text: String) -> [String] {
        var finalChunks: [String] = []
        var separator = separators.last!
        
        // Get appropriate separator to use
        for currentSeparator in separators {
            if currentSeparator.isEmpty {
                separator = currentSeparator
                break
            }
            
            if text.contains(currentSeparator) {
                separator = currentSeparator
                break
            }
        }
        
        // Now that we have the separator, split the text
        let splits = text.components(separatedBy: separator).compactMap { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        
        // Now go merging things, recursively splitting longer texts.
        var goodSplits: [String] = []
        
        for split in splits {
                        
            if lengthFunction(split) < chunkSize {
                
                // If the split's length is less than chunk_size, add it to _good_splits
                goodSplits.append(split)
                
            } else {
                
                // If there are any _good_splits, merge them and add to final_chunks
                if !goodSplits.isEmpty {
                    let mergedText = merge(splits: goodSplits, separator: separator)
                    finalChunks.append(contentsOf: mergedText)
                    goodSplits.removeAll()
                }
                
                // Recursively split the longer text and add it to final_chunks
                let otherInfo = self.split(text: split)
                finalChunks.append(contentsOf: otherInfo)
            }
        }
        
        // If there are any remaining _good_splits, merge and add to final_chunks
        if !goodSplits.isEmpty {
            let mergedText = merge(splits: goodSplits, separator: separator)
            finalChunks.append(contentsOf: mergedText)
        }
        
        return finalChunks
    }
}
