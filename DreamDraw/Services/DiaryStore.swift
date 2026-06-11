//
//  DiaryStore.swift
//  DreamDraw
//
//  그림 일기 목록을 앱 전체에서 공유하는 저장소입니다.
//

import Combine
import Foundation

@MainActor
final class DiaryStore: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    private(set) var entries: [DiaryEntry] = [] {
        didSet { objectWillChange.send() }
    }
    var errorMessage: String? {
        didSet { objectWillChange.send() }
    }

    private let persistence: PersistenceController

    init(persistence: PersistenceController? = nil) {
        self.persistence = persistence ?? PersistenceController.shared
    }

    func loadEntries() {
        do {
            entries = try persistence.loadEntries().sorted { $0.createdAt > $1.createdAt }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addEntry(_ entry: DiaryEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    private func save() {
        do {
            try persistence.saveEntries(entries)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    #if DEBUG
    /// SwiftUI Canvas 프리뷰용 저장소입니다.
    convenience init(previewEntries: [DiaryEntry]) {
        self.init()
        entries = previewEntries
    }
    #endif
}
