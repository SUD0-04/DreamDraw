//
//  DiaryViewModel.swift
//  DreamDraw
//
//  일기 목록 표시를 위한 날짜 그룹과 포맷을 제공합니다.
//

import Foundation

struct DiaryViewModel {
    let entries: [DiaryEntry]

    var sortedEntries: [DiaryEntry] {
        entries.sorted { $0.createdAt > $1.createdAt }
    }

    func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.year().month(.wide).day().weekday(.wide))
    }
}
