//
//  GuardianLockView.swift
//  DreamDraw
//
//  보호자 요약 화면 진입 전 비밀번호를 확인하는 잠금 화면입니다.
//

import Combine
import SwiftUI

struct GuardianLockView: View {
    @EnvironmentObject private var settings: AppSettingsStore

    let onUnlock: () -> Void

    @State private var code = ""
    @State private var showError = false

    private var passcodeLength: Int {
        settings.guardianPasscodeLength ?? 6
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(DreamDrawConstants.brandColor)
                .accessibilityHidden(true)

            Text("보호자 모드")
                .font(.title2.weight(.bold))

            Text("비밀번호 \(passcodeLength)자리를 입력해주세요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            PasscodeDotsField(length: passcodeLength, code: $code)

            if showError {
                Text("비밀번호가 일치하지 않아요.")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .onChange(of: code) { _, newValue in
            guard newValue.count == passcodeLength else { return }
            verify(newValue)
        }
    }

    private func verify(_ enteredCode: String) {
        // 마지막 점이 채워지는 것이 보이도록 잠시 기다렸다가 확인합니다.
        Task {
            try? await Task.sleep(for: .milliseconds(180))
            if settings.verifyGuardianPasscode(enteredCode) {
                onUnlock()
            } else {
                code = ""
                showError = true
            }
        }
    }
}

#if DEBUG
#Preview {
    GuardianLockView {}
        .environmentObject(AppSettingsStore())
}
#endif
