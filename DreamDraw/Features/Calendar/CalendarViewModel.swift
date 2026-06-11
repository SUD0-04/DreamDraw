//
//  CalendarViewModel.swift
//  DreamDraw
//
//  월간 감정 달력에 필요한 날짜 배열과 매핑을 만듭니다.
//

import Foundation

struct CalendarViewModel {
    let month: Date
    let entries: [DiaryEntry]

    private var calendar: Calendar {
        Calendar.current
    }

    var monthTitle: String {
        month.formatted(.dateTime.year().month(.wide))
    }

    var days: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let dayRange = calendar.range(of: .day, in: .month, for: month) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leadingEmptyDays = firstWeekday - calendar.firstWeekday
        let normalizedLeadingDays = leadingEmptyDays >= 0 ? leadingEmptyDays : leadingEmptyDays + 7
        let dates = dayRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: interval.start)
        }

        return Array(repeating: nil, count: normalizedLeadingDays) + dates
    }

    func entry(for date: Date) -> DiaryEntry? {
        entries.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
}
