//
//  ParagraphTextSplitter.swift
//  VectorNest
//
//  Created by Ronald Mannak on 4/25/23.
//

import Foundation
import GPTEncoder

public struct ParagraphTextSplitter: TextSplitter {
    
    static let encoder = GPTEncoder()
    
    public let lengthFunction: (String) -> Int
    
    public let text: String
    
    public let chunkSize: Int
    
    public let chunkOverlap: Int
    
    public init(text: String, chunkSize: Int = 4_000, chunkOverlap: Int = 200) throws {
        guard chunkSize > chunkOverlap else { throw TextSplitterError.invalidChunkSize }
        self.text = text
        self.chunkSize = chunkSize
        self.chunkOverlap = chunkOverlap
        self.lengthFunction = { Self.encoder.encode(text: $0).count }
    }
    
    public func split() -> [String] {

        // Segmenting text into paragraphs, removing empty segments (which trips ADA002)
        let paragraphs = text.components(separatedBy: "\n").compactMap { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        
        // For better semantic search results, combine segments in larger overlapping segments.
        var segments = [String]()
        let mergeCount = 8 // number of paragraphs in one segment
        
        // Skip index 0
        for index in 1 ..< paragraphs.count where index % mergeCount == 0 {
            print("index: \(index)")
            var newSegment = [String]()
            for sIndex in index - mergeCount ... index {
                newSegment.append(paragraphs[sIndex])
                print("sIndex: \(sIndex)")
            }
            segments.append(newSegment.joined(separator: " "))
            // Left over paragraphs
            
            let paragraphsLeft = paragraphs.count - index - 1
            if paragraphsLeft > 0 && paragraphsLeft < mergeCount {
                print("index at: \(index) is last before rest. Need to read \(paragraphsLeft)")
                var lastSegment = [String]()
                for sIndex in index ... index + paragraphsLeft {
                    lastSegment.append(paragraphs[sIndex])
                    print("Adding index \(sIndex)")
                }
                segments.append(lastSegment.joined(separator: " "))
            }
        }
//        print("paragraphs: \(paragraphs.count)")
        return segments
    }
}
