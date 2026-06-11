//
//  DiaryEntry.swift
//  DreamDraw
//
//  날짜별 그림 일기 데이터 모델입니다.
//

import Foundation

struct DiaryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let drawingData: Data
    let emotionResult: EmotionResult
    let createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        drawingData: Data,
        emotionResult: EmotionResult,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.drawingData = drawingData
        self.emotionResult = emotionResult
        self.createdAt = createdAt
    }
}
