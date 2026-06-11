//
//  EmotionInference.swift
//  DreamDraw
//
//  색상·선 패턴·채색 면적 분석을 바탕으로 감정 결과를 생성합니다.
//
//  1차: 학술 연구 기반 규칙으로 감정 후보를 추정하고 (근거데이터 문서 1~3장),
//  2차: Apple Intelligence (Foundation Models)가 사용 가능한 기기에서는
//       분석 데이터를 온디바이스 모델에 전달해 보호자용 자연어 요약을 생성합니다 (문서 4장).
//  모델을 사용할 수 없으면 규칙 기반 결과를 그대로 사용합니다.
//

import Foundation
import UIKit

#if canImport(FoundationModels)
import FoundationModels

/// 근거데이터 문서 4장의 출력 형식 (감정 키워드 / 보호자 요약 / 주의 사항)
@Generable
struct EmotionNarrative {
    @Guide(description: "그림에서 느껴지는 가장 가까운 감정 분류", .anyOf(["차분함", "기쁨", "불안", "슬픔", "활기", "복합 감정"]))
    let primaryEmotion: String

    @Guide(description: "감정 키워드 1~2개 (예: 차분함, 안정)", .minimumCount(1), .maximumCount(2))
    let keywords: [String]

    @Guide(description: "보호자가 이해하기 쉬운 따뜻한 한국어 2~3문장 요약. 진단하는 표현은 쓰지 않는다.")
    let guardianSummary: String

    @Guide(description: "주의가 필요한 경우에만 한 문장 (예: 평소보다 에너지가 많이 낮아 보입니다). 특별히 없으면 빈 문자열.")
    let cautionNote: String
}
#endif

struct EmotionInference {
    func inferEmotion(colors: ColorAnalysis, shape: ShapeAnalysis) async -> EmotionResult {
        let assessment = ResearchEmotionModel.assess(colors: colors, shape: shape)

        #if canImport(FoundationModels)
        if case .available = SystemLanguageModel.default.availability {
            if let aiResult = await appleIntelligenceResult(assessment: assessment, colors: colors, shape: shape) {
                return aiResult
            }
        }
        #endif

        return heuristicResult(assessment: assessment, colors: colors, shape: shape)
    }

    // MARK: - Apple Intelligence (Foundation Models)

    #if canImport(FoundationModels)
    private func appleIntelligenceResult(
        assessment: EmotionAssessment,
        colors: ColorAnalysis,
        shape: ShapeAnalysis
    ) async -> EmotionResult? {
        let instructions = """
        당신은 발달장애인의 그림을 분석하여 감정 상태를 따뜻하게 설명하는 보조 AI입니다.
        입력으로 학술 연구 기반으로 추출된 그림 특성 데이터가 주어집니다.
        이를 바탕으로 그림을 그린 사람의 감정 상태를 한국어로,
        보호자가 이해하기 쉬운 언어로 설명해주세요.
        의학적 진단이나 단정적인 표현은 피하고, 관찰과 제안 중심으로 말해주세요.
        """

        let colorList = colors.dominantColors
            .map { "\($0.hex) (\(Int($0.percentage * 100))%)" }
            .joined(separator: ", ")

        let prompt = """
        [입력 데이터]
        - 주요 색상: \(colorList.isEmpty ? "없음" : colorList)
        - 평균 밝기: \(String(format: "%.2f", colors.averageLightness)) / 평균 채도: \(String(format: "%.2f", colors.averageSaturation))
        - 채색 면적 비율: \(Int(colors.coloredAreaRatio * 100))% / 사용된 색상 수: \(colors.colorVariety)
        - 평균 필압: \(String(format: "%.2f", shape.averageForce)) / 평균 획 속도: \(Int(shape.averageSpeed))pt/초
        - 총 획 수: \(shape.strokeCount) / 평균 획 길이: \(Int(shape.averageStrokeLength))pt / 획 불규칙성: \(String(format: "%.2f", shape.irregularityScore))
        - 선 패턴 요약: \(shape.description)
        - 연구 기반 규칙의 1차 추정 감정: \(assessment.emotion.rawValue)

        이 데이터를 바탕으로 감정 상태를 분석해주세요.
        """

        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt, generating: EmotionNarrative.self)
            let narrative = response.content

            let emotion = DreamDrawEmotion(rawValue: narrative.primaryEmotion) ?? assessment.emotion
            let caution = narrative.cautionNote.trimmingCharacters(in: .whitespacesAndNewlines)

            return EmotionResult(
                primaryEmotion: emotion,
                summary: narrative.guardianSummary,
                keywords: narrative.keywords,
                cautionNote: caution.isEmpty ? assessment.cautionNote : caution,
                dominantColors: colors.dominantColors,
                shapeDescription: shape.description,
                confidence: min(0.95, assessment.confidence + 0.1),
                source: .appleIntelligence
            )
        } catch {
            // 가드레일 거부, 컨텍스트 초과 등 — 규칙 기반 결과로 폴백합니다.
            return nil
        }
    }
    #endif

    // MARK: - 연구 기반 규칙 폴백

    private func heuristicResult(
        assessment: EmotionAssessment,
        colors: ColorAnalysis,
        shape: ShapeAnalysis
    ) -> EmotionResult {
        EmotionResult(
            primaryEmotion: assessment.emotion,
            summary: warmSummary(for: assessment.emotion, colors: colors, shape: shape),
            keywords: assessment.keywords,
            cautionNote: assessment.cautionNote,
            dominantColors: colors.dominantColors,
            shapeDescription: shape.description,
            confidence: assessment.confidence,
            source: .researchHeuristic
        )
    }

    private func warmSummary(for emotion: DreamDrawEmotion, colors: ColorAnalysis, shape: ShapeAnalysis) -> String {
        let colorPhrase = colors.dominantColors.first.map { "가장 많이 보이는 색은 \($0.hex)입니다." } ?? "색상 정보가 많지 않습니다."

        switch emotion {
        case .calm:
            return "\(colorPhrase) \(shape.description) 지금은 마음을 천천히 정리하며 차분하게 표현하고 있는 것 같아요."
        case .joyful:
            return "\(colorPhrase) 밝은 색과 열린 선이 보여요. 즐겁거나 기대되는 마음이 그림 안에 담긴 것 같아요."
        case .worried:
            return "\(colorPhrase) 선과 색에서 조금 긴장된 느낌이 보여요. 옆에서 천천히 말을 걸어주면 좋겠습니다."
        case .sad:
            return "\(colorPhrase) 낮고 차분한 색감이 중심에 있어요. 조용한 위로와 안정적인 시간이 필요할 수 있어요."
        case .energetic:
            return "\(colorPhrase) 선의 움직임이 활발합니다. 에너지가 크거나 표현하고 싶은 마음이 많은 상태로 보여요."
        case .mixed:
            return "\(colorPhrase) 여러 감정이 함께 섞여 보입니다. 그림을 보며 어떤 부분이 가장 마음에 드는지 물어봐 주세요."
        }
    }
}

// MARK: - 연구 기반 감정 점수화

/// 근거데이터 문서의 3가지 분석 축을 가중 합산해 감정을 추정합니다.
/// 색상 50% (1장) + 선 패턴 35% (2장) + 채색 면적 15% (3장).
struct EmotionAssessment {
    let emotion: DreamDrawEmotion
    let secondaryEmotion: DreamDrawEmotion?
    let keywords: [String]
    let cautionNote: String?
    let confidence: Double
}

enum ResearchEmotionModel {
    static func assess(colors: ColorAnalysis, shape: ShapeAnalysis) -> EmotionAssessment {
        var scores: [DreamDrawEmotion: Double] = [:]

        merge(colorScores(colors), into: &scores, weight: 0.5)
        merge(strokeScores(shape), into: &scores, weight: 0.35)
        merge(areaScores(colors, shape: shape), into: &scores, weight: 0.15)

        let ranked = scores.sorted { $0.value > $1.value }
        guard let top = ranked.first, top.value > 0 else {
            return EmotionAssessment(
                emotion: .mixed,
                secondaryEmotion: nil,
                keywords: ["복합 감정"],
                cautionNote: nil,
                confidence: 0.45
            )
        }

        let runnerUp = ranked.dropFirst().first
        // 1·2위가 비등하면 복합 감정으로 판단합니다.
        let isMixed: Bool
        if let runnerUp, runnerUp.value / top.value > 0.85, runnerUp.key != top.key {
            isMixed = true
        } else {
            isMixed = false
        }

        let emotion = isMixed ? .mixed : top.key
        let secondary = isMixed ? top.key : runnerUp?.key
        let margin = runnerUp.map { (top.value - $0.value) / max(top.value, 0.001) } ?? 1

        return EmotionAssessment(
            emotion: emotion,
            secondaryEmotion: secondary,
            keywords: keywords(for: emotion, secondary: secondary),
            cautionNote: cautionNote(emotion: emotion, colors: colors, shape: shape),
            confidence: confidence(margin: margin, colors: colors, shape: shape)
        )
    }

    /// 1장: 주요 색상 Top 5에 색상-감정 매핑을 적용하고 비율로 가중 평균합니다.
    private static func colorScores(_ colors: ColorAnalysis) -> [DreamDrawEmotion: Double] {
        var scores: [DreamDrawEmotion: Double] = [:]
        for moodColor in colors.dominantColors {
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0
            UIColor(hex: moodColor.hex).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

            let weights = ColorEmotionMap.weights(
                hue: Double(hue),
                saturation: Double(saturation),
                brightness: Double(brightness)
            )
            for (emotion, weight) in weights {
                scores[emotion, default: 0] += weight * moodColor.percentage
            }
        }
        return scores
    }

    /// 2장: 선 패턴별 감정 추론 규칙.
    private static func strokeScores(_ shape: ShapeAnalysis) -> [DreamDrawEmotion: Double] {
        guard shape.strokeCount > 0 else { return [:] }
        var scores: [DreamDrawEmotion: Double] = [:]

        // 획 수: 많음 → 불안 또는 높은 에너지 / 적음 → 무기력·우울 가능성
        if shape.strokeCount > 18 {
            if shape.isIrregular {
                scores[.worried, default: 0] += 0.5
                scores[.energetic, default: 0] += 0.3
            } else {
                scores[.energetic, default: 0] += 0.5
                scores[.joyful, default: 0] += 0.2
            }
        } else if shape.strokeCount <= 3 {
            scores[.sad, default: 0] += 0.25
            scores[.calm, default: 0] += 0.2
        }

        // 획 속도: 매우 빠름 → 충동·불안·흥분 / 매우 느림 → 우울·피로
        if shape.isFastPaced {
            scores[.energetic, default: 0] += 0.35
            scores[.worried, default: 0] += shape.isIrregular ? 0.35 : 0.15
        } else if shape.isSlowPaced {
            scores[.calm, default: 0] += 0.3
            scores[.sad, default: 0] += 0.2
        }

        // 필압: 강함+빠름 → 흥분·강한 각성 / 약함+느림 → 차분·슬픔
        // (손가락 입력은 force가 1.0 부근에 고정되므로 중립 구간으로 둡니다.)
        if shape.averageForce > 1.5 && shape.isFastPaced {
            scores[.energetic, default: 0] += 0.3
        } else if shape.averageForce > 0, shape.averageForce < 0.7, shape.isSlowPaced {
            scores[.calm, default: 0] += 0.15
            scores[.sad, default: 0] += 0.15
        }

        // 획 길이: 짧고 불규칙 → 불안·긴장 / 길고 부드러움 → 안정·긍정
        if shape.averageStrokeLength < 50 && shape.isIrregular {
            scores[.worried, default: 0] += 0.4
        } else if shape.averageStrokeLength > 120 && !shape.isIrregular {
            scores[.calm, default: 0] += 0.3
            scores[.joyful, default: 0] += 0.15
        }

        return scores
    }

    /// 3장: 채색 면적 비율 규칙.
    private static func areaScores(_ colors: ColorAnalysis, shape: ShapeAnalysis) -> [DreamDrawEmotion: Double] {
        guard shape.strokeCount > 0 else { return [:] }
        var scores: [DreamDrawEmotion: Double] = [:]

        switch colors.coloredAreaRatio {
        case 0.7...:
            // 넓은 채색 → 감정 에너지 높음, 긍정적 활성 상태
            scores[.energetic, default: 0] += 0.4
            scores[.joyful, default: 0] += 0.3
        case ..<0.08:
            // 빈 공간이 매우 많음 → 회피·고립감·우울 가능성
            scores[.sad, default: 0] += 0.45
            scores[.worried, default: 0] += 0.2
        case ..<0.3:
            // 좁은 채색 → 에너지 낮음, 위축 가능성
            scores[.sad, default: 0] += 0.3
            scores[.calm, default: 0] += 0.15
        default:
            // 중간 → 중립 또는 혼합
            scores[.mixed, default: 0] += 0.2
            scores[.calm, default: 0] += 0.15
        }

        // 다양한 색을 함께 쓴 그림은 표현 에너지가 높은 편입니다.
        if colors.colorVariety >= 5 {
            scores[.joyful, default: 0] += 0.15
            scores[.energetic, default: 0] += 0.1
        }

        return scores
    }

    private static func merge(
        _ partial: [DreamDrawEmotion: Double],
        into scores: inout [DreamDrawEmotion: Double],
        weight: Double
    ) {
        let total = partial.values.reduce(0, +)
        guard total > 0 else { return }
        for (emotion, value) in partial {
            scores[emotion, default: 0] += (value / total) * weight
        }
    }

    private static func keywords(for emotion: DreamDrawEmotion, secondary: DreamDrawEmotion?) -> [String] {
        let primaryKeyword: String
        switch emotion {
        case .calm: primaryKeyword = "차분함"
        case .joyful: primaryKeyword = "기쁨"
        case .worried: primaryKeyword = "긴장"
        case .sad: primaryKeyword = "슬픔"
        case .energetic: primaryKeyword = "활기"
        case .mixed: primaryKeyword = "복합 감정"
        }

        if emotion == .mixed, let secondary, secondary != .mixed {
            return [primaryKeyword, "\(secondary.rawValue) 섞임"]
        }
        if let secondary, secondary != emotion, secondary != .mixed {
            return [primaryKeyword, secondary.rawValue]
        }
        return [primaryKeyword]
    }

    /// 보호자가 주의 깊게 봐야 할 신호 (근거데이터 문서의 출력 형식 '주의 사항' 항목).
    private static func cautionNote(
        emotion: DreamDrawEmotion,
        colors: ColorAnalysis,
        shape: ShapeAnalysis
    ) -> String? {
        if shape.strokeCount > 0, shape.strokeCount <= 4, colors.coloredAreaRatio < 0.15 {
            return "채색 면적과 선이 평소보다 적어 에너지가 낮아 보여요. 오늘 컨디션을 살펴봐 주세요."
        }
        if shape.isFastPaced && shape.isIrregular {
            return "짧고 빠른 선이 많아 긴장하거나 초조한 상태일 수 있어요. 천천히 대화를 시도해 주세요."
        }
        if emotion == .sad && colors.averageLightness < 0.35 {
            return "어두운 색이 중심이라 마음이 가라앉아 있을 수 있어요. 조용히 곁에 있어 주세요."
        }
        return nil
    }

    private static func confidence(margin: Double, colors: ColorAnalysis, shape: ShapeAnalysis) -> Double {
        // 신호량(획 수·채색 면적)과 1·2위 점수 차이가 클수록 신뢰도가 올라갑니다.
        let signalAmount = min(0.2, Double(shape.strokeCount) / 40 + colors.coloredAreaRatio * 0.2)
        let marginBonus = min(0.25, margin * 0.4)
        return min(0.95, 0.5 + signalAmount + marginBonus)
    }
}
