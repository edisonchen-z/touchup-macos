//
//  OllamaClient.swift
//  TouchUp
//
//  Created by Edison Chen on 12/22/25.
//

import Foundation
import os

/// Errors that can occur during Ollama communication
enum OllamaError: Error {
    case connectionFailed(Error)
    case modelNotFound
    case timeout
    case emptyResponse
    case invalidResponse
    case serverError(String)
}

/// Client for communicating with local Ollama REST API
class OllamaClient {
    
    // MARK: - Configuration
    
    private let baseURL = "http://127.0.0.1:11434"
    private let model = "qwen3:4b" // Hardcoded for v1
    private let timeout: TimeInterval = 30.0
    
    private let session: URLSession
    
    // MARK: - Initialization
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
        
        appLogger.info("OllamaClient initialized (model: \(self.model), baseURL: \(self.baseURL))")
    }
    
    // MARK: - Public Methods
    
    /// Polish the given text using Ollama
    /// - Parameter input: Text to polish
    /// - Returns: Polished text
    /// - Throws: OllamaError if request fails
    func polishText(_ input: String) async throws -> String {
        appLogger.info("Sending text to Ollama (\(input.count) chars)")
        let startTime = Date()
        
        // Build the prompt
        let prompt = buildPolishPrompt(input)
        
        // Create the request
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw OllamaError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build request body
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "stream": false // Non-streaming for v1
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        // Make the request
        let (data, response) = try await session.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }
        
        // Handle different status codes
        switch httpResponse.statusCode {
        case 200:
            // Success - parse response
            let polishedText = try parseResponse(data)
            
            let duration = Date().timeIntervalSince(startTime) * 1000
            appLogger.info("Received polished text (\(polishedText.count) chars, \(String(format: "%.0f", duration))ms)")
            
            return polishedText
            
        case 404:
            appLogger.error("Model '\(self.model)' not found")
            throw OllamaError.modelNotFound
            
        default:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            appLogger.error("Ollama server error (\(httpResponse.statusCode)): \(errorMessage)")
            throw OllamaError.serverError(errorMessage)
        }
    }
    
    /// Check if Ollama server is running
    /// - Returns: True if Ollama is accessible
    func checkHealth() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            return false
        }
        
        do {
            let (_, response) = try await session.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                let isHealthy = httpResponse.statusCode == 200
                appLogger.info("Ollama health check: \(isHealthy ? "OK" : "Failed")")
                return isHealthy
            }
        } catch {
            appLogger.error("Ollama health check failed: \(error.localizedDescription)")
        }
        
        return false
    }
    
    // MARK: - Private Methods
    
    /// Build the polishing prompt
    private func buildPolishPrompt(_ input: String) -> String {
        return """
        You are a professional writing assistant. Polish the following text by:
        1. Correcting any grammar, spelling, or punctuation errors
        2. Rewriting it in a professional business tone
        3. Maintaining the original meaning and structure
        
        Return ONLY the polished text without any explanations, quotes, or meta-commentary.
        
        Text to polish:
        \(input)
        """
    }
    
    /// Parse the Ollama response to extract polished text
    private func parseResponse(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            appLogger.error("Failed to parse Ollama response as JSON")
            throw OllamaError.invalidResponse
        }
        
        // Extract the message content from the response
        // Response format: {"message": {"role": "assistant", "content": "..."}, ...}
        guard let message = json["message"] as? [String: Any],
              let content = message["content"] as? String,
              !content.isEmpty else {
            appLogger.error("Empty or invalid response from Ollama")
            throw OllamaError.emptyResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Error Extensions

extension OllamaError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .connectionFailed(let error):
            return "Cannot connect to Ollama: \(error.localizedDescription)"
        case .modelNotFound:
            return "Model not found. Run: ollama pull qwen2.5:3b"
        case .timeout:
            return "Request timed out"
        case .emptyResponse:
            return "Ollama returned an empty response"
        case .invalidResponse:
            return "Invalid response from Ollama"
        case .serverError(let message):
            return "Ollama error: \(message)"
        }
    }
}
