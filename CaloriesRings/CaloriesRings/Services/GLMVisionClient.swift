import Foundation
import UIKit

struct MacroEstimate: Codable, Sendable {
    let foodName: String
    let servingSize: String
    let calories: Int
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let confidence: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case servingSize = "serving_size"
        case calories
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case confidence, notes
    }

    // LLMs may return calories as 450.0, fields may be missing — be lenient
    nonisolated init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        foodName    = (try? c.decode(String.self, forKey: .foodName)) ?? "Unknown food"
        servingSize = (try? c.decode(String.self, forKey: .servingSize)) ?? "1 serving"
        if let intCal = try? c.decode(Int.self, forKey: .calories) {
            calories = intCal
        } else if let dblCal = try? c.decode(Double.self, forKey: .calories) {
            calories = Int(dblCal)
        } else {
            calories = 0
        }
        proteinG   = (try? c.decode(Double.self, forKey: .proteinG)) ?? 0
        carbsG     = (try? c.decode(Double.self, forKey: .carbsG)) ?? 0
        fatG       = (try? c.decode(Double.self, forKey: .fatG)) ?? 0
        confidence = (try? c.decode(String.self, forKey: .confidence)) ?? "medium"
        notes      = try? c.decodeIfPresent(String.self, forKey: .notes)
    }
}

enum GLMError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse(String)
    case apiError(String)

    nonisolated var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Z.AI API key not set. Add it in Settings."
        case .invalidResponse: return "Could not analyse the photo. Please try again."
        case .apiError(let msg): return msg
        }
    }
}

actor GLMVisionClient {
    static let shared = GLMVisionClient()
    private let baseURL = "https://api.z.ai/api/coding/paas/v4/chat/completions"
    private let model = "glm-4.6v-flash"

    func analyzeFood(image: UIImage) async throws -> MacroEstimate {
        guard let apiKey = KeychainClient.load() else { throw GLMError.missingAPIKey }
        guard let jpegData = image.jpegData(compressionQuality: 0.7) else {
            throw GLMError.invalidResponse("Failed to encode image as JPEG.")
        }
        let base64 = jpegData.base64EncodedString()

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "temperature": 0.1,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "image_url",
                     "image_url": ["url": "data:image/jpeg;base64,\(base64)"]],
                    ["type": "text",
                     "text": """
                     Analyze this food photo. Return ONLY a JSON object (no markdown, no explanation) \
                     with exactly these keys: food_name (string), serving_size (string), \
                     calories (integer kcal), protein_g (number), carbs_g (number), fat_g (number), \
                     confidence ("low"|"medium"|"high"), notes (string or null).
                     """]
                ]
            ]]
        ]

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        // Surface HTTP errors before trying to decode
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw GLMError.apiError("HTTP \(http.statusCode): \(String(body.prefix(200)))")
        }

        struct APIResponse: Decodable, Sendable {
            struct Choice: Decodable, Sendable {
                struct Message: Decodable, Sendable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }

        let apiResp = try JSONDecoder().decode(APIResponse.self, from: data)
        let content = apiResp.choices.first?.message.content ?? ""

        // Extract first {...} block, handling markdown fences
        let jsonString: String
        if let start = content.firstIndex(of: "{"),
           let end = content.lastIndex(of: "}") {
            jsonString = String(content[start...end])
        } else {
            throw GLMError.invalidResponse("No JSON found in: \(String(content.prefix(300)))")
        }

        guard let jsonData = jsonString.data(using: .utf8),
              let estimate = try? JSONDecoder().decode(MacroEstimate.self, from: jsonData)
        else {
            throw GLMError.invalidResponse("Parse failed for: \(String(jsonString.prefix(300)))")
        }

        return estimate
    }
}
