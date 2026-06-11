//
//  EmotionResult.swift
//  DreamDraw
//
//  그림 분석 결과와 감정 요약을 담는 모델입니다.
//

import SwiftUI

struct EmotionResult: Identifiable, Codable, Equatable {
    /// 감정 결과를 만든 분석 경로입니다.
    enum AnalysisSource: String, Codable, Equatable {
        /// Apple Intelligence (Foundation Models) 온디바이스 추론
        case appleIntelligence
        /// 학술 연구 기반 규칙 분석 (Foundation Models 미지원 기기 폴백)
        case researchHeuristic

        var displayName: String {
            switch self {
            case .appleIntelligence: "Apple Intelligence 온디바이스 분석"
            case .researchHeuristic: "연구 데이터 기반 분석"
            }
        }

        var symbolName: String {
            switch self {
            case .appleIntelligence: "sparkles"
            case .researchHeuristic: "books.vertical"
            }
        }
    }

    let id: UUID
    let primaryEmotion: DreamDrawEmotion
    let summary: String
    /// 감정 키워드 1~2개 (근거데이터 문서의 출력 형식)
    let keywords: [String]
    /// 보호자가 주의 깊게 봐야 할 사항. 없으면 nil.
    let cautionNote: String?
    let dominantColors: [MoodColor]
    let shapeDescription: String
    let confidence: Double
    let source: AnalysisSource

    init(
        id: UUID = UUID(),
        primaryEmotion: DreamDrawEmotion,
        summary: String,
        keywords: [String] = [],
        cautionNote: String? = nil,
        dominantColors: [MoodColor],
        shapeDescription: String,
        confidence: Double,
        source: AnalysisSource = .researchHeuristic
    ) {
        self.id = id
        self.primaryEmotion = primaryEmotion
        self.summary = summary
        self.keywords = keywords
        self.cautionNote = cautionNote
        self.dominantColors = dominantColors
        self.shapeDescription = shapeDescription
        self.confidence = confidence
        self.source = source
    }

    // 기존에 저장된 일기(키워드·주의사항·출처 필드가 없던 버전)도 읽을 수 있도록 합니다.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        primaryEmotion = try container.decode(DreamDrawEmotion.self, forKey: .primaryEmotion)
        summary = try container.decode(String.self, forKey: .summary)
        keywords = try container.decodeIfPresent([String].self, forKey: .keywords) ?? []
        cautionNote = try container.decodeIfPresent(String.self, forKey: .cautionNote)
        dominantColors = try container.decode([MoodColor].self, forKey: .dominantColors)
        shapeDescription = try container.decode(String.self, forKey: .shapeDescription)
        confidence = try container.decode(Double.self, forKey: .confidence)
        source = try container.decodeIfPresent(AnalysisSource.self, forKey: .source) ?? .researchHeuristic
    }
}

struct MoodColor: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let hex: String
    let percentage: Double

    init(id: UUID = UUID(), hex: String, percentage: Double) {
        self.id = id
        self.hex = hex
        self.percentage = percentage
    }
}

enum DreamDrawEmotion: String, Codable, CaseIterable, Identifiable {
    case calm = "차분함"
    case joyful = "기쁨"
    case worried = "불안"
    case sad = "슬픔"
    case energetic = "활기"
    case mixed = "복합 감정"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .calm: "leaf"
        case .joyful: "sun.max"
        case .worried: "wind"
        case .sad: "cloud.rain"
        case .energetic: "bolt.heart"
        case .mixed: "circle.hexagongrid"
        }
    }

    var color: Color {
        switch self {
        case .calm: Color(red: 0.31, green: 0.63, blue: 0.58)
        case .joyful: Color(red: 0.95, green: 0.66, blue: 0.20)
        case .worried: Color(red: 0.48, green: 0.42, blue: 0.72)
        case .sad: Color(red: 0.28, green: 0.48, blue: 0.76)
        case .energetic: Color(red: 0.86, green: 0.32, blue: 0.28)
        case .mixed: DreamDrawConstants.brandColor
        }
    }
}
