//
//  ResearchSourcesView.swift
//  DreamDraw
//
//  감정 분석에 활용한 학술 연구 출처를 보여주는 화면입니다.
//

import SwiftUI

struct ResearchSourcesView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Source: Identifiable {
        let id = UUID()
        let title: String
        let publisher: String
        let year: String
        let urlString: String
    }

    private struct SourceSection: Identifiable {
        let id = UUID()
        let name: String
        let sources: [Source]
    }

    private let sections: [SourceSection] = [
        SourceSection(name: "색상과 감정", sources: [
            Source(
                title: "Do we feel colours? A systematic review (132편 메타분석)",
                publisher: "Mohr & Jonauskaite, Psychonomic Bulletin & Review",
                year: "2025",
                urlString: "https://link.springer.com/article/10.3758/s13423-024-02615-z"
            ),
            Source(
                title: "International Color-Emotion Association Survey (90개국 12,000명)",
                publisher: "Mohr et al.",
                year: "2018~",
                urlString: "https://www.psychologytoday.com/us/blog/color-psychology"
            ),
            Source(
                title: "Text-to-image models reveal color-emotion associations",
                publisher: "Alvarado, Frontiers in Psychology",
                year: "2025",
                urlString: "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12202424/"
            )
        ]),
        SourceSection(name: "선 패턴과 감정", sources: [
            Source(
                title: "The Impact of Motion Features of Hand-drawn Lines on Emotional Expression",
                publisher: "ScienceDirect",
                year: "2024",
                urlString: "https://www.sciencedirect.com/science/article/abs/pii/S0097849324000244"
            ),
            Source(
                title: "Drawing as a window to emotion",
                publisher: "Nature Scientific Reports",
                year: "2024",
                urlString: "https://www.nature.com/articles/s41598-024-60532-6"
            ),
            Source(
                title: "Emotion detection from handwriting and drawing",
                publisher: "PMC / Frontiers in Neuroscience",
                year: "2024",
                urlString: "https://pmc.ncbi.nlm.nih.gov/articles/PMC11041987/"
            ),
            Source(
                title: "Modifying stylus input using inferred emotion (특허 US9229543)",
                publisher: "USPTO",
                year: "2016",
                urlString: "https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9229543"
            )
        ]),
        SourceSection(name: "채색 면적과 감정 건강", sources: [
            Source(
                title: "Effects of Expressive Arts–Based Interventions on Adults with Intellectual Disabilities",
                publisher: "PMC",
                year: "2020",
                urlString: "https://pmc.ncbi.nlm.nih.gov/articles/PMC7300289/"
            ),
            Source(
                title: "Empowering People with IDD through Cognitively Accessible Visualizations",
                publisher: "arXiv",
                year: "2023",
                urlString: "https://arxiv.org/pdf/2309.12194"
            )
        ])
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("DreamDraw의 감정 분석 규칙과 Apple Intelligence 프롬프트는 아래 학술 연구를 근거로 설계되었습니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }

                ForEach(sections) { section in
                    Section(section.name) {
                        ForEach(section.sources) { source in
                            if let url = URL(string: source.urlString) {
                                Link(destination: url) {
                                    sourceRow(source)
                                }
                                .accessibilityLabel("\(source.title), \(source.publisher), \(source.year). 링크 열기")
                            } else {
                                sourceRow(source)
                            }
                        }
                    }
                }
            }
            .navigationTitle("참고 연구 출처")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                        .accessibilityLabel("출처 화면 닫기")
                }
            }
        }
    }

    private func sourceRow(_ source: Source) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(source.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Text("\(source.publisher) · \(source.year)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#if DEBUG
#Preview {
    ResearchSourcesView()
}
#endif
