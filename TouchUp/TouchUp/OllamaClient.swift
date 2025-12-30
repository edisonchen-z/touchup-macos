//
//  OllamaClient.swift
//  TouchUp
//
//  Created by Edison Chen on 12/22/25.
//

import Foundation
import os

/// Model information from Ollama
struct OllamaModel: Identifiable, Codable {
    let name: String
    let modifiedAt: String
    let size: Int64
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name
        case modifiedAt = "modified_at"
        case size
    }
}

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
    private let timeout: TimeInterval = 30.0
    
    /// Get the currently selected model from settings
    private var selectedModel: String {
        SettingsManager.shared.getSelectedModel()
    }
    
    // Generation parameters
    private let temperature: Double = 0.1
    private let topP: Double = 0.85
    private let topK: Int = 20
    private let repeatPenalty: Double = 1.1
    
    private let session: URLSession
    
    // MARK: - Initialization
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
        
        appLogger.info("OllamaClient initialized (baseURL: \(self.baseURL))")
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
        appLogger.info("Full Prompt Sent to Ollama:\n\(prompt)")
        
        // Create the request
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw OllamaError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build request body
        let requestBody: [String: Any] = [
            "model": selectedModel,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "stream": false, // Non-streaming for v1
            "options": [
                "temperature": temperature,
                "top_p": topP,
                "top_k": topK,
                "repeat_penalty": repeatPenalty
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        // Make the request
        let networkStartTime = Date()
        let (data, response) = try await session.data(for: request)
        let networkDuration = Date().timeIntervalSince(networkStartTime) * 1000
        appLogger.info("Ollama Latency: \(String(format: "%.0f", networkDuration))ms")
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }
        
        // Handle different status codes
        switch httpResponse.statusCode {
        case 200:
            // Success - parse response
            let polishedText = try parseResponse(data)
            
            let totalDuration = Date().timeIntervalSince(startTime) * 1000
            appLogger.info("Received polished text (\(polishedText.count) chars, total: \(String(format: "%.0f", totalDuration))ms)")
            
            return polishedText
            
        case 404:
            appLogger.error("Model '\(self.selectedModel)' not found")
            throw OllamaError.modelNotFound
            
        default:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            appLogger.error("Ollama server error (\(httpResponse.statusCode)): \(errorMessage)")
            throw OllamaError.serverError(errorMessage)
        }
    }
    
    /// List all installed Ollama models
    /// - Returns: Array of installed models
    /// - Throws: OllamaError if request fails
    func listInstalledModels() async throws -> [OllamaModel] {
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            throw OllamaError.invalidResponse
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OllamaError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw OllamaError.serverError("Status code: \(httpResponse.statusCode)")
            }
            
            // Parse the response
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let modelsArray = json["models"] as? [[String: Any]] else {
                appLogger.error("Failed to parse models response")
                throw OllamaError.invalidResponse
            }
            
            // Convert to OllamaModel objects
            let models = modelsArray.compactMap { modelDict -> OllamaModel? in
                guard let name = modelDict["name"] as? String,
                      let modifiedAt = modelDict["modified_at"] as? String,
                      let size = modelDict["size"] as? Int64 else {
                    return nil
                }
                return OllamaModel(name: name, modifiedAt: modifiedAt, size: size)
            }
            
            appLogger.info("Found \(models.count) installed Ollama models")
            return models
            
        } catch let error as OllamaError {
            throw error
        } catch {
            appLogger.error("Failed to list models: \(error.localizedDescription)")
            throw OllamaError.connectionFailed(error)
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
    /// Build the polishing prompt
    private func buildPolishPrompt(_ input: String) -> String {
        let instruction: String
        
        if SettingsManager.shared.customPromptEnabled {
            instruction = SettingsManager.shared.customPromptText
        } else {
            instruction = SettingsManager.shared.defaultInstruction
        }
        
        // Always append the fixed suffix to ensure correct output format
        let suffix = SettingsManager.shared.promptSuffix
        
        return """
        \(instruction)
        
        \(suffix)
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
