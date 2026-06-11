//
//  DiaryDetailView.swift
//  DreamDraw
//
//  개별 그림 일기의 그림, 감정, 색상 분석을 보여줍니다.
//

import PencilKit
import SwiftUI

struct DiaryDetailView: View {
    let entry: DiaryEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DrawingThumbnail(data: entry.drawingData)
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("저장된 그림")

                HStack {
                    Label(entry.emotionResult.primaryEmotion.rawValue, systemImage: entry.emotionResult.primaryEmotion.symbolName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(entry.emotionResult.primaryEmotion.color)
                    Spacer()
                    Text(entry.createdAt.formatted(.dateTime.hour().minute()))
                        .foregroundStyle(.secondary)
                }

                if !entry.emotionResult.keywords.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(entry.emotionResult.keywords, id: \.self) { keyword in
                            Text(keyword)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .foregroundStyle(entry.emotionResult.primaryEmotion.color)
                                .background(entry.emotionResult.primaryEmotion.color.opacity(0.14), in: Capsule())
                                .accessibilityLabel("감정 키워드 \(keyword)")
                        }
                    }
                }

                Text(entry.emotionResult.summary)
                    .font(.body)
                    .lineSpacing(4)

                if let caution = entry.emotionResult.cautionNote, !caution.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .accessibilityHidden(true)
                        Text(caution)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityLabel("주의 사항. \(caution)")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("선 패턴")
                        .font(.headline)
                    Text(entry.emotionResult.shapeDescription)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("색상 팔레트")
                        .font(.headline)
                    ForEach(entry.emotionResult.dominantColors) { color in
                        HStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color(hex: color.hex))
                                .frame(width: 42, height: 28)
                            Text(color.hex)
                            Spacer()
                            Text("\(Int(color.percentage * 100))%")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Label(entry.emotionResult.source.displayName, systemImage: entry.emotionResult.source.symbolName)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
            .padding()
        }
        .navigationTitle(entry.date.formatted(.dateTime.month().day()))
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        DiaryDetailView(entry: PreviewData.sampleEntry)
    }
}
#endif
