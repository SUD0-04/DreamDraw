//
//  Constants.swift
//  DreamDraw
//
//  앱 전역 스타일과 분석 기준값을 정의합니다.
//

import SwiftUI

enum DreamDrawConstants {
    static let brandColor = Color(red: 0.48, green: 0.37, blue: 0.65)
    static let brandLightColor = Color(red: 0.93, green: 0.91, blue: 0.96)
    static let minimumTapSize: CGFloat = 44

    static let sampleResult = EmotionResult(
        primaryEmotion: .calm,
        summary: "부드러운 색과 안정적인 선이 보여요. 지금은 차분하게 마음을 표현하고 있는 것 같아요.",
        keywords: ["차분함", "안정"],
        dominantColors: [
            MoodColor(hex: "#7B5EA7", percentage: 0.42),
            MoodColor(hex: "#5E9F94", percentage: 0.28),
            MoodColor(hex: "#F0A832", percentage: 0.16)
        ],
        shapeDescription: "선이 비교적 안정적이고 부드럽게 이어집니다.",
        confidence: 0.72
    )
}

/// 색상-감정 매핑 테이블.
///
/// 근거: Mohr & Jonauskaite (2025, Psychonomic Bulletin & Review) 132편 메타분석,
/// International Color-Emotion Association Survey (Mohr et al., 2018) 등
/// `DrawMood_AI_감정판단_근거데이터.md` 1장의 색상별 감정 매핑 및 밝기·채도 규칙을 따릅니다.
enum ColorEmotionMap {
    /// HSB 값 하나에 대한 감정 가중치를 돌려줍니다. 가중치 합은 1로 정규화됩니다.
    static func weights(hue: Double, saturation: Double, brightness: Double) -> [DreamDrawEmotion: Double] {
        var weights = baseWeights(hue: hue, saturation: saturation, brightness: brightness)

        // 밝기 규칙: 밝을수록 긍정(valence)↑, 어두울수록 슬픔·우울 방향.
        if brightness >= 0.7 {
            weights[.joyful, default: 0] += 0.12
            weights[.calm, default: 0] += 0.08
        } else if brightness <= 0.35 {
            weights[.sad, default: 0] += 0.18
        }

        // 채도 규칙: 높으면 각성(arousal)↑, 낮으면 차분·무기력 방향.
        if saturation >= 0.65 {
            weights[.energetic, default: 0] += 0.12
            // 빨강 + 고채도는 흥분·분노 강도가 가장 높음.
            if hue < 0.05 || hue > 0.93 {
                weights[.energetic, default: 0] += 0.08
                weights[.worried, default: 0] += 0.05
            }
        } else if saturation <= 0.3 {
            weights[.calm, default: 0] += 0.08
            weights[.sad, default: 0] += 0.05
        }

        return normalized(weights)
    }

    /// Hue 기반 1차 매핑. 근거데이터 문서의 색상별 감정 매핑 테이블을 6개 앱 감정으로 투영했습니다.
    private static func baseWeights(hue: Double, saturation: Double, brightness: Double) -> [DreamDrawEmotion: Double] {
        // 무채색: 검정·회색 → 슬픔·두려움 (신뢰 수준 높음), 흰색 근처 → 중립·평온.
        guard saturation >= 0.12 else {
            if brightness < 0.25 { return [.sad: 0.55, .worried: 0.45] }
            if brightness < 0.7 { return [.sad: 0.6, .worried: 0.25, .mixed: 0.15] }
            return [.calm: 1.0]
        }

        switch hue {
        case ..<0.042, 0.93...:
            // 빨강: 분노·흥분 (주) / 사랑·열정 (보조)
            return [.energetic: 0.55, .worried: 0.25, .joyful: 0.2]
        case ..<0.11:
            // 주황 계열. 어두우면 갈색 → 슬픔·불쾌.
            return brightness < 0.45
                ? [.sad: 0.6, .mixed: 0.4]
                : [.joyful: 0.6, .energetic: 0.4]
        case ..<0.175:
            // 노랑: 기쁨·행복 (주) / 에너지·낙관 (보조)
            return [.joyful: 0.75, .energetic: 0.25]
        case ..<0.46:
            // 초록: 긍정·안정 (주) / 감사·평온 (보조)
            return [.calm: 0.75, .joyful: 0.25]
        case ..<0.72:
            // 파랑: 차분함·평온. 어두운 파랑은 슬픔 방향.
            return brightness < 0.45
                ? [.sad: 0.55, .calm: 0.45]
                : [.calm: 0.8, .joyful: 0.1, .sad: 0.1]
        case ..<0.86:
            // 보라: 슬픔·신비 (주) / 수줍음 (보조) — 신뢰 수준 중간이라 분산 배치.
            return [.sad: 0.4, .worried: 0.25, .calm: 0.35]
        default:
            // 분홍: 사랑·온화함 (주) / 행복 (보조)
            return [.joyful: 0.65, .calm: 0.35]
        }
    }

    private static func normalized(_ weights: [DreamDrawEmotion: Double]) -> [DreamDrawEmotion: Double] {
        let total = weights.values.reduce(0, +)
        guard total > 0 else { return weights }
        return weights.mapValues { $0 / total }
    }
}
