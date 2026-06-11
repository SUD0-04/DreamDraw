//
//  ContentView.swift
//  DreamDraw
//
//  DreamDraw의 루트 화면입니다. 첫 실행 시 온보딩을, 이후에는 탭 화면을 보여줍니다.
//

import Combine
import SwiftUI

struct ContentView: View {
    @StateObject private var diaryStore: DiaryStore
    @StateObject private var settings: AppSettingsStore

    init() {
        _diaryStore = StateObject(wrappedValue: DiaryStore())
        _settings = StateObject(wrappedValue: AppSettingsStore())
    }

    #if DEBUG
    init(previewStore: DiaryStore, previewSettings: AppSettingsStore? = nil) {
        _diaryStore = StateObject(wrappedValue: previewStore)
        _settings = StateObject(wrappedValue: previewSettings ?? AppSettingsStore())
    }
    #endif

    var body: some View {
        Group {
            if settings.hasCompletedOnboarding {
                mainTabs
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .environmentObject(diaryStore)
        .environmentObject(settings)
        .tint(DreamDrawConstants.brandColor)
        .animation(.easeInOut(duration: 0.35), value: settings.hasCompletedOnboarding)
    }

    private var mainTabs: some View {
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
