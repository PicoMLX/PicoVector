//
//  ContentView.swift
//  VectorDatabaseExample
//
//  Created by Ronald Mannak on 4/26/23.
//

import SwiftUI
import PDFKit
import VectorNest
import OpenAIKit
import AsyncHTTPClient

struct ContentView: View {
    
    private let openAI: OpenAIKit.Client
    private let key = "sk-YOUR OPENAI KEY HERE"
    private let org = "org-YOUR OPENAI ORG HERE"
    
    @State private var label = "Drop a PDF"
    @State private var error: Error?
    @State private var showError = false
    @State private var vectorDB = VectorNest()
    @State private var query = ""
    @State private var response = ""
    @State private var isStreaming = false
    
    init() {
        let configuration = Configuration(apiKey: key, organization: org)
        let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
        openAI = OpenAIKit.Client(httpClient: httpClient, configuration: configuration)
    }
    
    var body: some View {
        
        Text("VectorNest demo")
            .fontWeight(.bold)
            .font(.title)
            .padding()
            .foregroundColor(.purple)
        
        Text(label)
            .frame(width: 120, height: 120)
            .fontWeight(.bold)
            .font(.title)
            .padding()
            .foregroundColor(.purple)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.purple.opacity(0.25))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: 5, dash: [15]))
            )
            .padding()
            .dropDestination(for: Data.self) { items, location in
                label = "Parsing..."
                
                // Store all text from dropped PDFs in text
                var text = ""
                for item in items {
                    if let content = PDFDocument(data: item)?.string {
                        text.append(content)
                    }
                }
                
                Task {
                    do {
                        
                        // Divide text in smaller chunks
                        let chunks = try RecursiveTextSplitter(text: text).split()
                        
                        // Create embeddings
                        let embeddings = try await openAI.embeddings.create(input: chunks)
                        
                        // Store embeddings in VectorNest
                        vectorDB.addDocument(chunks: chunks, vectors: embeddings.data.map({ $0.embedding }))
                    } catch {
                        self.error = error
                        showError = true
                    }
                    label = "Parsed"
                }
                return !text.isEmpty
            }
            .alert(self.error?.localizedDescription ?? "Unknown error", isPresented: $showError) {
                        Button("OK", role: .cancel) { }
            }
        
        if vectorDB.chunks.isEmpty {
            Spacer()
        } else {
                    
            // GPT response
            ScrollView {
                Text(response)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding([.leading, .trailing])
            
            // User input
            TextField("Ask me anything about the PDF", text: $query)
                .disabled(self.isStreaming)
                .padding()
                .onSubmit {
                    Task {
                        do {
                            
                            // Create embedding for query
                            guard let queryEmbedding = try await openAI.embeddings.create(input: [query]).data.first?.embedding else {
                                response.append("\n---\nError embedding query")
                                return
                            }
                                                         
                            // Find closest matches in PDF embeddings for query embedding
                            let results = vectorDB.ranking(query: queryEmbedding)
                             
                            // Fetch corresponding text from PDF
                            var searchResults = ""
                            for index in results.0 {
                                searchResults = searchResults + vectorDB.chunks[index] + "\n---\n"
                            }

                            // Create prompt
                            let prompt = """
                                Use the search results below. If the answer cannot be found, write "I can't find that information in the PDF."

                                Search results:
                                ===
                                \(searchResults)
                                ===

                                Question: \(query)
                                """
                                        
                            // Send prompt to OpenAI
                            let stream = try await openAI.chats.stream(
                                model: Model.GPT4.gpt4,
                                messages: [
                                    .user(content: prompt)
                                ],
                                temperature: 0.0
                            )
                            
                            // Stream completion to response view
                            if !response.isEmpty {
                                response.append("\n---\n")
                            }
                            
                            response.append("Q: \(query)\nA: ")
                            
                            isStreaming = true
                            for try await chat in stream {
                                if let message = chat.choices.first?.delta.content {
                                    response = response + message
                                }
                            }
                            isStreaming = false
                            query = ""
                        } catch {
                            isStreaming = false
                            self.error = error
                            showError = true
                        }
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
