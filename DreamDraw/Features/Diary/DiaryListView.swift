//
//  DiaryListView.swift
//  DreamDraw
//
//  날짜별 그림 일기를 목록으로 보여줍니다.
//

import Combine
import PencilKit
import SwiftUI

struct DiaryListView: View {
    @EnvironmentObject private var diaryStore: DiaryStore

    var body: some View {
        NavigationStack {
            Group {
                if diaryStore.entries.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(DiaryViewModel(entries: diaryStore.entries).sortedEntries) { entry in
                            NavigationLink {
                                DiaryDetailView(entry: entry)
                            } label: {
                                DiaryEntryRow(entry: entry)
                            }
                            .accessibilityLabel("\(entry.emotionResult.primaryEmotion.rawValue) 그림 일기")
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("그림 일기")
            .alert("저장 오류", isPresented: Binding(
                get: { diaryStore.errorMessage != nil },
                set: { if !$0 { diaryStore.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(diaryStore.errorMessage ?? "저장된 일기를 불러오지 못했어요.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "paintpalette")
                .font(.system(size: 54))
                .foregroundStyle(DreamDrawConstants.brandColor)
                .accessibilityHidden(true)

            Text("아직 그림 일기가 없어요")
                .font(.title3.weight(.semibold))

            Text("오늘의 감정을 그려보세요.")
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

private struct DiaryEntryRow: View {
    let entry: DiaryEntry

    var body: some View {
        HStack(spacing: 14) {
            DrawingThumbnail(data: entry.drawingData)
                .frame(width: 64, height: 64)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.date.formatted(.dateTime.month(.wide).day().weekday(.abbreviated)))
                    .font(.headline)

                Label(entry.emotionResult.primaryEmotion.rawValue, systemImage: entry.emotionResult.primaryEmotion.symbolName)
                    .font(.subheadline)
                    .foregroundStyle(entry.emotionResult.primaryEmotion.color)

                Text(entry.emotionResult.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DrawingThumbnail: View {
    @Environment(\.displayScale) private var displayScale

    let data: Data

    var body: some View {
        if let image = thumbnailImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding(6)
        } else {
            Image(systemName: "scribble")
                .foregroundStyle(.secondary)
        }
    }

    private var thumbnailImage: UIImage? {
        guard let drawing = try? PKDrawing(data: data) else { return nil }
        let bounds = drawing.bounds.isEmpty ? CGRect(x: 0, y: 0, width: 240, height: 240) : drawing.bounds.insetBy(dx: -12, dy: -12)
        return drawing.image(from: bounds, scale: displayScale)
    }
}

#if DEBUG
#Preview("빈 목록") {
    DiaryListView()
        .environmentObject(DiaryStore(previewEntries: []))
}

#Preview("일기 있음") {
    DiaryListView()
        .environmentObject(DiaryStore(previewEntries: PreviewData.sampleEntries))
}
#endif
