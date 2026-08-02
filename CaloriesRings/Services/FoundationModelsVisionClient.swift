import Foundation
import FoundationModels
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

    nonisolated init(
        foodName: String,
        servingSize: String,
        calories: Int,
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        confidence: String,
        notes: String?
    ) {
        self.foodName = foodName
        self.servingSize = servingSize
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.confidence = confidence
        self.notes = notes
    }

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

enum FoodAnalysisError: Error, LocalizedError {
    case unavailable(String)
    case invalidResponse(String)
    case apiError(String)

    nonisolated var errorDescription: String? {
        switch self {
        case .unavailable(let reason): return reason
        case .invalidResponse: return "Could not analyse the photo. Please try again."
        case .apiError(let msg): return msg
        }
    }
}

actor FoundationModelsVisionClient {
    static let shared = FoundationModelsVisionClient()

    func analyzeFood(image: UIImage) async throws -> MacroEstimate {
        try await FoundationModelsFoodAnalyzer().analyzeFood(image: image)
    }
}

private struct FoundationModelsFoodAnalyzer {
    func analyzeFood(image: UIImage) async throws -> MacroEstimate {
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            throw FoodAnalysisError.unavailable(unavailableMessage(for: model.availability))
        }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            Estimate nutrition from food photos. Return realistic values for the visible portion only. \
            If the image does not contain food, identify it as unknown food with zero macros and low confidence.
            """
        )
        let prompt = Prompt {
            """
            Analyze this food photo and estimate calories plus macronutrients for the visible serving. \
            Use grams for protein, carbohydrates, and fat. Keep notes short and practical.
            """
            Attachment(image).label("food-photo")
        }
        let response = try await session.respond(
            to: prompt,
            generating: GeneratedMacroEstimate.self,
            options: GenerationOptions(samplingMode: .greedy, temperature: 0.1, maximumResponseTokens: 512)
        )

        return response.content.macroEstimate
    }

    private func unavailableMessage(for availability: SystemLanguageModel.Availability) -> String {
        switch availability {
        case .available:
            return "Apple Intelligence is available. Please try again."
        case .unavailable(.deviceNotEligible):
            return "Food scanning requires a device that supports Apple Intelligence."
        case .unavailable(.modelNotReady):
            return "Apple Intelligence is still preparing on this device. Try again later."
        case .unavailable:
            return "Apple Intelligence is not available on this device."
        @unknown default:
            return "Apple Intelligence is not available right now."
        }
    }
}

@Generable(description: "A nutrition estimate for the food visible in a photo.")
private struct GeneratedMacroEstimate {
    @Guide(description: "Brief common name for the visible food.")
    let foodName: String

    @Guide(description: "Estimated visible serving size, such as 1 bowl, 2 slices, or 250 g.")
    let servingSize: String

    @Guide(description: "Estimated total calories in kilocalories for the visible serving.")
    let calories: Int

    @Guide(description: "Estimated grams of protein in the visible serving.")
    let proteinG: Double

    @Guide(description: "Estimated grams of carbohydrates in the visible serving.")
    let carbsG: Double

    @Guide(description: "Estimated grams of fat in the visible serving.")
    let fatG: Double

    @Guide(description: "Confidence level for the estimate.")
    let confidence: EstimateConfidence

    @Guide(description: "Short note about uncertainty, assumptions, or visible ingredients.")
    let notes: String?

    var macroEstimate: MacroEstimate {
        MacroEstimate(
            foodName: foodName,
            servingSize: servingSize,
            calories: max(calories, 0),
            proteinG: max(proteinG, 0),
            carbsG: max(carbsG, 0),
            fatG: max(fatG, 0),
            confidence: confidence.rawValue,
            notes: notes
        )
    }
}

@Generable(description: "Confidence level for a nutrition estimate.")
private enum EstimateConfidence: String {
    case low
    case medium
    case high
}
