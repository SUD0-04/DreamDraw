//
//  EmotionResultView.swift
//  DreamDraw
//
//  분석된 감정 결과를 저장 전 확인하는 시트입니다.
//

import SwiftUI

struct EmotionResultView: View {
    let result: EmotionResult
    let onSave: () -> Void

    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if !result.keywords.isEmpty {
                        keywordChips
                    }

                    Text(result.summary)
                        .font(.body)
                        .lineSpacing(4)
                        .accessibilityLabel("감정 요약 \(result.summary)")

                    if let caution = result.cautionNote, !caution.isEmpty {
                        cautionCard(caution)
                    }

                    colorPalette

                    VStack(alignment: .leading, spacing: 8) {
                        Text("선 패턴")
                            .font(.headline)
                        Text(result.shapeDescription)
                            .foregroundStyle(.secondary)
                    }

                    sourceBadge
                }
                .padding()
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 24)
            }
            .navigationTitle("분석 결과")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", action: onSave)
                        .accessibilityLabel("그림 일기 저장")
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    hasAppeared = true
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: result.primaryEmotion.symbolName)
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(result.primaryEmotion.color, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(result.primaryEmotion.rawValue)
                    .font(.title2.weight(.bold))
                Text("신뢰도 \(Int(result.confidence * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var keywordChips: some View {
        HStack(spacing: 8) {
            ForEach(result.keywords, id: \.self) { keyword in
                Text(keyword)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .foregroundStyle(result.primaryEmotion.color)
                    .background(result.primaryEmotion.color.opacity(0.14), in: Capsule())
                    .accessibilityLabel("감정 키워드 \(keyword)")
            }
        }
    }

    private func cautionCard(_ caution: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("주의 깊게 봐주세요")
                    .font(.subheadline.weight(.semibold))
                Text(caution)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("주의 사항. \(caution)")
    }

    private var colorPalette: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("주요 색상")
                .font(.headline)
            HStack(spacing: 8) {
                ForEach(result.dominantColors) { color in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(hex: color.hex))
                            .frame(height: 46)
                        Text("\(Int(color.percentage * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(color.hex), \(Int(color.percentage * 100))퍼센트")
                }
            }
        }
    }

    private var sourceBadge: some View {
        Label(result.source.displayName, systemImage: result.source.symbolName)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
            .accessibilityLabel(result.source.displayName)
    }
}

#if DEBUG
#Preview("규칙 기반") {
    EmotionResultView(result: DreamDrawConstants.sampleResult) {}
}

#Preview("주의 사항 포함") {
    EmotionResultView(
        result: EmotionResult(
            primaryEmotion: .sad,
            summary: "낮고 차분한 색감이 중심에 있어요. 조용한 위로와 안정적인 시간이 필요할 수 있어요.",
            keywords: ["슬픔", "차분함"],
            cautionNote: "채색 면적과 선이 평소보다 적어 에너지가 낮아 보여요. 오늘 컨디션을 살펴봐 주세요.",
            dominantColors: [
                MoodColor(hex: "#2E4A78", percentage: 0.58),
                MoodColor(hex: "#5A5A5A", percentage: 0.24)
            ],
            shapeDescription: "선이 느리고 적어 에너지가 낮은 상태일 수 있습니다.",
            confidence: 0.66,
            source: .appleIntelligence
        )
    ) {}
}
#endif
