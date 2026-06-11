//
//  GuardianSummaryView.swift
//  DreamDraw
//
//  보호자와 활동보조인을 위한 최근 감정 요약 화면입니다.
//

import Charts
import Combine
import SwiftUI

struct GuardianSummaryView: View {
    @EnvironmentObject private var diaryStore: DiaryStore

    var body: some View {
        let viewModel = GuardianViewModel(entries: diaryStore.entries)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryCard(viewModel)

                    if !viewModel.cautionEntries.isEmpty {
                        cautionCard(viewModel.cautionEntries)
                    }

                    if !viewModel.chartData.isEmpty {
                        emotionChart(viewModel.chartData)
                    }

                    recentList(viewModel.recentEntries)
                }
                .padding()
            }
            .navigationTitle("보호자 요약")
            .background(Color(.systemGroupedBackground))
        }
    }

    private func summaryCard(_ viewModel: GuardianViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("최근 7일", systemImage: "heart.text.square")
                .font(.headline)
                .foregroundStyle(DreamDrawConstants.brandColor)

            Text(viewModel.headline)
                .font(.title3.weight(.bold))

            Text(viewModel.detail)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    /// 최근 7일 중 주의 사항이 있었던 날을 모아 보여줍니다.
    private func cautionCard(_ entries: [DiaryEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("주의 깊게 봐주세요", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            ForEach(entries) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.date.formatted(.dateTime.month().day().weekday(.abbreviated)))
                        .font(.subheadline.weight(.semibold))
                    Text(entry.emotionResult.cautionNote ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)

                if entry.id != entries.last?.id {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func emotionChart(_ data: [GuardianDaySummary]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("감정 흐름")
                .font(.headline)

            Chart(data) { item in
                LineMark(
                    x: .value("날짜", item.date, unit: .day),
                    y: .value("감정 점수", item.score)
                )
                .foregroundStyle(DreamDrawConstants.brandColor)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("날짜", item.date, unit: .day),
                    y: .value("감정 점수", item.score)
                )
                .foregroundStyle(item.emotion.color)
            }
            .chartYScale(domain: 1...5)
            .chartYAxis {
                AxisMarks(values: [1, 2, 3, 4, 5])
            }
            .frame(height: 210)
            .accessibilityLabel("최근 7일 감정 흐름 차트")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func recentList(_ entries: [DiaryEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 기록")
                .font(.headline)

            if entries.isEmpty {
                Text("아직 표시할 기록이 없습니다.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(entries) { entry in
                    HStack(spacing: 12) {
                        Image(systemName: entry.emotionResult.primaryEmotion.symbolName)
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(entry.emotionResult.primaryEmotion.color, in: Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.date.formatted(.dateTime.month().day().weekday(.abbreviated)))
                                .font(.subheadline.weight(.semibold))
                            Text(entry.emotionResult.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 6)

                    if entry.id != entries.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#if DEBUG
#Preview("빈 요약") {
    GuardianSummaryView()
        .environmentObject(DiaryStore(previewEntries: []))
}

#Preview("7일 기록") {
    GuardianSummaryView()
        .environmentObject(DiaryStore(previewEntries: PreviewData.sampleEntries))
}
#endif
