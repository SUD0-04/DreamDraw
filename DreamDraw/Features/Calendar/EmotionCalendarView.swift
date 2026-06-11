//
//  EmotionCalendarView.swift
//  DreamDraw
//
//  월간 달력에 감정 색상을 표시합니다.
//

import Combine
import SwiftUI

struct EmotionCalendarView: View {
    @EnvironmentObject private var diaryStore: DiaryStore
    @State private var month = Date()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekdays = Calendar.current.shortWeekdaySymbols

    var body: some View {
        let viewModel = CalendarViewModel(month: month, entries: diaryStore.entries)

        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    monthHeader(viewModel)

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(weekdays, id: \.self) { weekday in
                            Text(weekday)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }

                        ForEach(Array(viewModel.days.enumerated()), id: \.offset) { _, date in
                            if let date {
                                dayCell(date: date, entry: viewModel.entry(for: date))
                            } else {
                                Color.clear
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }

                    emotionLegend
                }
                .padding()
            }
            .navigationTitle("감정 달력")
            .background(Color(.systemGroupedBackground))
        }
    }

    private func monthHeader(_ viewModel: CalendarViewModel) -> some View {
        HStack {
            Button {
                month = Calendar.current.date(byAdding: .month, value: -1, to: month) ?? month
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: DreamDrawConstants.minimumTapSize, height: DreamDrawConstants.minimumTapSize)
            }
            .accessibilityLabel("이전 달")

            Spacer()

            Text(viewModel.monthTitle)
                .font(.title2.weight(.bold))

            Spacer()

            Button {
                month = Calendar.current.date(byAdding: .month, value: 1, to: month) ?? month
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: DreamDrawConstants.minimumTapSize, height: DreamDrawConstants.minimumTapSize)
            }
            .accessibilityLabel("다음 달")
        }
    }

    private func dayCell(date: Date, entry: DiaryEntry?) -> some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.callout.weight(.semibold))
            if let entry {
                Image(systemName: entry.emotionResult.primaryEmotion.symbolName)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(
            (entry?.emotionResult.primaryEmotion.color.opacity(0.28) ?? Color(.secondarySystemBackground)),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(entry == nil ? Color.clear : entry!.emotionResult.primaryEmotion.color, lineWidth: 1)
        }
        .accessibilityLabel(accessibilityText(date: date, entry: entry))
    }

    private var emotionLegend: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(DreamDrawEmotion.allCases) { emotion in
                Label(emotion.rawValue, systemImage: emotion.symbolName)
                    .font(.caption)
                    .foregroundStyle(emotion.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, 8)
    }

    private func accessibilityText(date: Date, entry: DiaryEntry?) -> String {
        let day = date.formatted(.dateTime.month().day())
        if let entry {
            return "\(day), \(entry.emotionResult.primaryEmotion.rawValue)"
        }
        return "\(day), 기록 없음"
    }
}

#if DEBUG
#Preview("빈 달력") {
    EmotionCalendarView()
        .environmentObject(DiaryStore(previewEntries: []))
}

#Preview("기록 있음") {
    EmotionCalendarView()
        .environmentObject(DiaryStore(previewEntries: PreviewData.sampleEntries))
}
#endif
