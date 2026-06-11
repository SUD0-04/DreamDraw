//
//  AppSettingsStore.swift
//  DreamDraw
//
//  아동 이름, 온보딩 완료 여부, 보호자 모드 비밀번호를 관리합니다.
//  비밀번호는 원문 대신 SHA256 해시로 저장합니다.
//

import Combine
import CryptoKit
import Foundation

@MainActor
final class AppSettingsStore: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    private enum Keys {
        static let childName = "dreamdraw.childName"
        static let hasCompletedOnboarding = "dreamdraw.hasCompletedOnboarding"
        static let guardianPasscodeHash = "dreamdraw.guardianPasscodeHash"
        static let guardianPasscodeLength = "dreamdraw.guardianPasscodeLength"
    }

    private let defaults: UserDefaults

    var childName: String {
        didSet {
            defaults.set(childName, forKey: Keys.childName)
            objectWillChange.send()
        }
    }

    var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
            objectWillChange.send()
        }
    }

    private(set) var guardianPasscodeHash: String?
    private(set) var guardianPasscodeLength: Int?

    var hasGuardianPasscode: Bool { guardianPasscodeHash != nil }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        childName = defaults.string(forKey: Keys.childName) ?? ""
        hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        guardianPasscodeHash = defaults.string(forKey: Keys.guardianPasscodeHash)
        let storedLength = defaults.integer(forKey: Keys.guardianPasscodeLength)
        guardianPasscodeLength = storedLength > 0 ? storedLength : nil
    }

    /// nil을 전달하면 비밀번호를 설정하지 않은 상태가 됩니다.
    func setGuardianPasscode(_ code: String?) {
        if let code, !code.isEmpty {
            guardianPasscodeHash = Self.hash(code)
            guardianPasscodeLength = code.count
            defaults.set(guardianPasscodeHash, forKey: Keys.guardianPasscodeHash)
            defaults.set(code.count, forKey: Keys.guardianPasscodeLength)
        } else {
            guardianPasscodeHash = nil
            guardianPasscodeLength = nil
            defaults.removeObject(forKey: Keys.guardianPasscodeHash)
            defaults.removeObject(forKey: Keys.guardianPasscodeLength)
        }
        objectWillChange.send()
    }

    func verifyGuardianPasscode(_ code: String) -> Bool {
        guard let guardianPasscodeHash else { return true }
        return Self.hash(code) == guardianPasscodeHash
    }

    private static func hash(_ code: String) -> String {
        SHA256.hash(data: Data(code.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
