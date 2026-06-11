//
//  PersistenceController.swift
//  DreamDraw
//
//  MVP 단계에서 FileManager 기반 로컬 저장을 담당합니다.
//

import Foundation

enum PersistenceError: LocalizedError {
    case documentsDirectoryMissing
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .documentsDirectoryMissing:
            "저장 위치를 찾을 수 없어요."
        case .saveFailed:
            "그림 일기를 저장하지 못했어요."
        }
    }
}

final class PersistenceController {
    static let shared = PersistenceController()

    private let fileName = "dreamdraw-diary.json"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func loadEntries() throws -> [DiaryEntry] {
        let url = try storageURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try decoder.decode([DiaryEntry].self, from: data)
    }

    func saveEntries(_ entries: [DiaryEntry]) throws {
        let url = try storageURL()
        let data = try encoder.encode(entries)
        try data.write(to: url, options: [.atomic])
    }

    private func storageURL() throws -> URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw PersistenceError.documentsDirectoryMissing
        }
        return documentsURL.appendingPathComponent(fileName)
    }
}
