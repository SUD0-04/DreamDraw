//
//  ContentView.swift
//  DreamDraw
//
//  DreamDraw의 루트 탭 화면입니다.
//

import Combine
import SwiftUI

struct ContentView: View {
    @StateObject private var diaryStore: DiaryStore

    init() {
        _diaryStore = StateObject(wrappedValue: DiaryStore())
    }

    #if DEBUG
    init(previewStore: DiaryStore) {
        _diaryStore = StateObject(wrappedValue: previewStore)
    }
    #endif

    var body: some View {
        TabView {
            DrawingView()
                .tabItem {
                    Label("그리기", systemImage: "pencil.and.outline")
                }
                .accessibilityLabel("그리기 탭")

            DiaryListView()
                .tabItem {
                    Label("일기", systemImage: "book")
                }
                .accessibilityLabel("일기 탭")

            EmotionCalendarView()
                .tabItem {
                    Label("달력", systemImage: "calendar")
                }
                .accessibilityLabel("감정 달력 탭")

            GuardianSummaryView()
                .tabItem {
                    Label("보호자", systemImage: "person.2")
                }
                .accessibilityLabel("보호자 요약 탭")
        }
        .environmentObject(diaryStore)
        .tint(DreamDrawConstants.brandColor)
        .task {
            diaryStore.loadEntries()
        }
    }
}

#if DEBUG
#Preview("전체 앱") {
    ContentView()
}

#Preview("샘플 데이터") {
    ContentView(previewStore: DiaryStore(previewEntries: PreviewData.sampleEntries))
}
#endif
