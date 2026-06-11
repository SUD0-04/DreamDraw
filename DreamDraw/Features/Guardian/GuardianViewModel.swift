//
//  GuardianViewModel.swift
//  DreamDraw
//
//  보호자가 최근 감정 흐름을 볼 수 있도록 데이터를 요약합니다.
//

import Foundation

struct GuardianDaySummary: Identifiable {
    let id = UUID()
    let date: Date
    let emotion: DreamDrawEmotion
    let score: Int
}

struct GuardianViewModel {
    let entries: [DiaryEntry]

    var recentEntries: [DiaryEntry] {
        Array(entries.sorted { $0.createdAt > $1.createdAt }.prefix(7))
    }

    var headline: String {
        guard let latest = recentEntries.first else {
            return "최근 기록이 아직 없어요."
        }
        return "최근 기록은 \(latest.emotionResult.primaryEmotion.rawValue) 감정이 중심이에요."
    }

    var detail: String {
        guard let latest = recentEntries.first else {
            return "그리기 탭에서 첫 감정 그림을 남기면 보호자 요약이 자동으로 만들어집니다."
        }
        return latest.emotionResult.summary
    }

    /// 최근 7일 중 주의 사항이 기록된 일기 (최신순)
    var cautionEntries: [DiaryEntry] {
        recentEntries.filter { !($0.emotionResult.cautionNote ?? "").isEmpty }
    }

    var chartData: [GuardianDaySummary] {
        recentEntries.reversed().map {
            GuardianDaySummary(
                date: $0.date,
                emotion: $0.emotionResult.primaryEmotion,
                score: score(for: $0.emotionResult.primaryEmotion)
            )
        }
    }

    private func score(for emotion: DreamDrawEmotion) -> Int {
        switch emotion {
        case .sad: 1
        case .worried: 2
        case .mixed: 3
        case .calm: 4
        case .joyful, .energetic: 5
        }
    }
}
