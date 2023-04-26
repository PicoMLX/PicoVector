//
//  VectorNest.swift
//  VectorNest
//
//  Created by Ronald Mannak on 4/25/23.
//

import Foundation
import Accelerate

public class VectorNest {
    
    public var chunks: [String]
    public var vectors: [[Float]]

    public init() {
        chunks = [String]()
        vectors = [[Float]]()
    }
    
    public func addDocument(chunks: [String], vectors: [[Float]]) {
        self.chunks.append(contentsOf: chunks)
        self.vectors.append(contentsOf: vectors)
    }
}

// MARK: - Math
extension VectorNest {
    
    public func ranking(query: [Float], limit: Int = 5) -> ([Int], [Float]) {
        return ranking(vectors: vectors, query: query, limit: limit, using: cosineSimilarity(v1:v2:))
    }
    
    func ranking(vectors: [[Float]], query: [Float], limit: Int = 5, using metric: ([Float], [Float]) -> Float) -> ([Int], [Float]) {
    
        // Calculate similarities using the provided metric function
        let similarities: [Float] = vectors.map { metric($0, query) }
        
        // Find the indices of top-k similarity values
        let sortedIndices = (0..<similarities.count).sorted(by: { similarities[$0] > similarities[$1] })
        let topIndices = Array(sortedIndices.prefix(limit))
        
        // Extract top-k similarity values
        let topSimilarities = topIndices.map { similarities[$0] }
        
        return (topIndices, topSimilarities)
    }
    
    public func cosineSimilarity(v1: [Float], v2: [Float]) -> Float {
        assert(v1.count == v2.count, "Vectors must have the same dimensions")
        return dot(v1: v1, v2: v2) / (magnitude(vector: v1) * magnitude(vector: v2))
    }
    
    public func euclideanDistance(vector1: [Float], vector2: [Float]) -> Float {
        guard vector1.count == vector2.count else {
            fatalError("Vectors must have the same length.")
        }
        
        let count = vector1.count
        var squaredDifferences: [Float] = Array(repeating: 0.0, count: count)
        
        // Calculate the differences between corresponding elements
        vDSP_vsub(vector1, 1, vector2, 1, &squaredDifferences, 1, vDSP_Length(count))
            
        // Calculate the squared differences
        vDSP_vsq(squaredDifferences, 1, &squaredDifferences, 1, vDSP_Length(count))
            
        // Calculate the sum of squared differences
        var sumOfSquaredDifferences: Float = 0.0
        vDSP_sve(squaredDifferences, 1, &sumOfSquaredDifferences, vDSP_Length(count))
            
        // Calculate the Euclidean distance (square root of the sum)
        let euclideanDistance = sqrt(sumOfSquaredDifferences)
            
        return euclideanDistance
    }
    
    func dot(v1: [Float], v2: [Float]) -> Float {
        assert(v1.count == v2.count, "Vectors must have the same dimensions")
        var result: Float = 0.0
        vDSP_dotpr(v1, 1, v2, 1, &result, vDSP_Length(v1.count))
        return result
    }
    
    func magnitude(vector: [Float]) -> Float {
        var squaredValues = [Float](repeating: 0.0, count: vector.count)
        vDSP_vsq(vector, 1, &squaredValues, 1, vDSP_Length(vector.count))

        var sum: Float = 0.0
        vDSP_sve(squaredValues, 1, &sum, vDSP_Length(vector.count))
        return sqrt(sum)
    }

    func normalize(vector: [Float]) -> [Float] {
        let count = vector.count
        
        // Calculate the magnitude (norm) of the vector
        var magnitude: Float = 0.0
        vDSP_svesq(vector, 1, &magnitude, vDSP_Length(count))
        magnitude = sqrt(magnitude)
        
        // Normalize the vector by dividing its elements by the magnitude
        var normalizedVector: [Float] = Array(repeating: 0.0, count: count)
        vDSP_vsdiv(vector, 1, &magnitude, &normalizedVector, 1, vDSP_Length(count))
        
        return normalizedVector
    }
}
