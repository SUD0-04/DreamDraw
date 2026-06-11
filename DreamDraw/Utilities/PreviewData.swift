//
//  PreviewData.swift
//  DreamDraw
//
//  SwiftUI Canvas 프리뷰용 샘플 데이터입니다.
//

import Foundation
import PencilKit

#if DEBUG
enum PreviewData {
    static let emptyDrawingData = PKDrawing().dataRepresentation()

    static var sampleEntries: [DiaryEntry] {
        let emotions: [DreamDrawEmotion] = [.calm, .joyful, .worried, .sad, .energetic, .mixed, .calm]
        let summaries: [String] = [
            "부드러운 색과 안정적인 선이 보여요. 차분하게 마음을 표현하고 있는 것 같아요.",
            "밝은 색과 열린 선이 보여요. 즐겁거나 기대되는 마음이 담긴 것 같아요.",
            "선과 색에서 조금 긴장된 느낌이 보여요. 천천히 말을 걸어주면 좋겠습니다.",
            "낮고 차분한 색감이 중심에 있어요. 조용한 위로가 필요할 수 있어요.",
            "선의 움직임이 활발합니다. 표현하고 싶은 마음이 많은 상태로 보여요.",
            "여러 감정이 함께 섞여 보입니다. 그림을 보며 대화를 나눠 보세요.",
            "오늘도 그림으로 감정을 잘 표현했어요."
        ]

        let keywords: [[String]] = [
            ["차분함", "안정"],
            ["기쁨", "기대"],
            ["긴장", "초조"],
            ["슬픔", "위로 필요"],
            ["활기", "에너지"],
            ["복합 감정"],
            ["차분함"]
        ]

        return emotions.enumerated().map { index, emotion in
            let date = Calendar.current.date(byAdding: .day, value: -index, to: Date()) ?? Date()
            return DiaryEntry(
                date: date,
                drawingData: emptyDrawingData,
                emotionResult: EmotionResult(
                    primaryEmotion: emotion,
                    summary: summaries[index],
                    keywords: keywords[index],
                    cautionNote: emotion == .sad
                        ? "채색 면적과 선이 평소보다 적어 에너지가 낮아 보여요. 오늘 컨디션을 살펴봐 주세요."
                        : nil,
                    dominantColors: DreamDrawConstants.sampleResult.dominantColors,
                    shapeDescription: DreamDrawConstants.sampleResult.shapeDescription,
                    confidence: 0.68 + Double(index) * 0.03,
                    source: index.isMultiple(of: 2) ? .appleIntelligence : .researchHeuristic
                ),
                createdAt: date
            )
        }
    }

    static var sampleEntry: DiaryEntry {
        sampleEntries[0]
    }
}
#endif
