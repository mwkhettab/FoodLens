import UIKit

class APIService {
    internal var baseUrl = "http://localhost:8000/api/v1/food"
    
    public func analyzeImage(uiImage: UIImage) async throws -> AnalyzeImageResponse {
        guard let url = URL(string: baseUrl + "/analyze-image") else {
            throw URLError(.badURL)
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        
        guard let pngData = uiImage.pngData() else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }
        
        body.append(pngData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        let decoded = try JSONDecoder().decode(AnalyzeImageResponse.self, from: data)
        return decoded
    }
    
    
    public func estimateCalories(foodName: String, details: String, questions: [String], answers: [String]) async throws -> EstimateCaloriesResponse {
        guard let url = URL(string: baseUrl + "/estimate-calories") else {
            throw URLError(.badURL)
        }
        
        var answersDict: [String: String] = [:]
        for (index, question) in questions.enumerated() {
            if index < answers.count {
                answersDict[question] = answers[index]
            }
        }
        
        let json: [String: Any] = [
            "food_name": foodName,
            "details": details,
            "answers": answersDict
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        let decoded = try JSONDecoder().decode(EstimateCaloriesResponse.self, from: data)
        return decoded
    }
    
    public func chat(message: String, conversationHistory: [[String: String]]? = nil) async throws -> ChatResponse {
        guard let url = URL(string: baseUrl + "/chat") else {
            throw URLError(.badURL)
        }
        
        var json: [String: Any] = [
            "message": message
        ]
        
        if let history = conversationHistory {
            json["conversation_history"] = history
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        return decoded
    }
    
}

struct AnalyzeImageResponse: Codable {
    let food_name: String
    let details: String
    let questions: [String]
}

struct EstimateCaloriesResponse: Codable {
    let calories: Float
    let macronutrients: MacroNutrients
    let micronutrients: MicroNutrients
    let health_score: Int
    let health_insights: [String]
    let portion_size: String
    let confidence_level: Int
}

struct MacroNutrients: Codable {
    let protein_g: Float
    let carbs_g: Float
    let fat_g: Float
    let fiber_g: Float
}

struct MicroNutrients: Codable {
    let sodium_mg: Float
    let sugar_g: Float
    let saturated_fat_g: Float
    let cholesterol_mg: Float
}

struct ChatResponse: Codable {
    let response: String
    let conversation_history: [[String: String]]
}
