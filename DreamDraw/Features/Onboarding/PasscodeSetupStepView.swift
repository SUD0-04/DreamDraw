//
//  PasscodeSetupStepView.swift
//  DreamDraw
//
//  온보딩 마지막 단계: 보호자 모드 비밀번호를 설정합니다.
//  기본 6자리이며, 기타 설정에서 4자리 또는 설정하지 않기를 선택할 수 있습니다.
//

import Combine
import SwiftUI

struct PasscodeSetupStepView: View {
    /// 설정된 비밀번호를 전달합니다. 설정하지 않기를 선택하면 nil입니다.
    let onComplete: (String?) -> Void

    private enum PasscodeOption: Hashable {
        case sixDigits
        case fourDigits
        case none

        var length: Int? {
            switch self {
            case .sixDigits: 6
            case .fourDigits: 4
            case .none: nil
            }
        }
    }

    private enum Phase {
        case enter
        case confirm
        case done
    }

    @State private var option: PasscodeOption = .sixDigits
    @State private var phase: Phase = .enter
    @State private var enteredCode = ""
    @State private var firstCode = ""
    @State private var confirmedCode: String?
    @State private var showMismatchError = false
    @State private var isOptionDialogPresented = false

    private var requiredLength: Int { option.length ?? 6 }

    private var canFinish: Bool {
        option == .none || confirmedCode != nil
    }

    private var promptText: String {
        switch phase {
        case .enter: "비밀번호 \(requiredLength)자리를 입력해주세요"
        case .confirm: "확인을 위해 한 번 더 입력해주세요"
        case .done: "비밀번호가 설정되었어요"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: option == .none ? "lock.open" : "lock.shield")
                        .font(.system(size: 56))
                        .foregroundStyle(DreamDrawConstants.brandColor)
                        .accessibilityHidden(true)

                    Text("보호자 모드 비밀번호")
                        .font(.title.weight(.bold))

                    Text("보호자 요약 화면을 열 때 사용하는 비밀번호예요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if option == .none {
                        noPasscodeWarning
                            .padding(.top, 12)
                    } else {
                        passcodeEntry
                            .padding(.top, 12)
                    }

                    Button("기타 설정") {
                        isOptionDialogPresented = true
                    }
                    .font(.subheadline)
                    .frame(minHeight: DreamDrawConstants.minimumTapSize)
                    .padding(.top, 6)
                    .accessibilityLabel("비밀번호 기타 설정")
                }
                .padding(.horizontal, 28)
                .padding(.top, 72)
            }

            OnboardingNextButton(title: "다음", isEnabled: canFinish) {
                onComplete(option == .none ? nil : confirmedCode)
            }
        }
        .confirmationDialog("비밀번호 설정 방식", isPresented: $isOptionDialogPresented, titleVisibility: .visible) {
            Button("6자리 비밀번호 (기본)") { switchOption(to: .sixDigits) }
            Button("4자리 비밀번호") { switchOption(to: .fourDigits) }
            Button("설정하지 않기", role: .destructive) { switchOption(to: .none) }
            Button("취소", role: .cancel) {}
        }
        .onChange(of: enteredCode) { _, newValue in
            handleCodeChange(newValue)
        }
    }

    private var passcodeEntry: some View {
        VStack(spacing: 14) {
            Text(promptText)
                .font(.subheadline.weight(.semibold))

            if phase == .done {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
                    .accessibilityLabel("비밀번호 설정 완료")
            } else {
                PasscodeDotsField(length: requiredLength, code: $enteredCode)
            }

            if showMismatchError {
                Text("비밀번호가 일치하지 않아요. 처음부터 다시 입력해주세요.")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    /// 설정하지 않기를 선택했을 때 표시되는 경고입니다.
    private var noPasscodeWarning: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("비밀번호를 설정하지 않아요")
                    .font(.subheadline.weight(.semibold))
                Text("비밀번호가 없으면 누구나 보호자 요약과 주의 기록을 볼 수 있어요. 나중에라도 설정하는 것을 권장해요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("경고. 비밀번호가 없으면 누구나 보호자 요약을 볼 수 있어요.")
    }

    private func switchOption(to newOption: PasscodeOption) {
        option = newOption
        phase = .enter
        enteredCode = ""
        firstCode = ""
        confirmedCode = nil
        showMismatchError = false
    }

    private func handleCodeChange(_ newValue: String) {
        guard newValue.count == requiredLength else { return }

        // 마지막 점이 채워지는 것이 보이도록 잠시 기다렸다가 다음 단계로 넘어갑니다.
        Task {
            try? await Task.sleep(for: .milliseconds(180))

            switch phase {
            case .enter:
                firstCode = newValue
                enteredCode = ""
                showMismatchError = false
                phase = .confirm
            case .confirm:
                if newValue == firstCode {
                    confirmedCode = newValue
                    withAnimation(.easeOut(duration: 0.25)) {
                        phase = .done
                    }
                } else {
                    enteredCode = ""
                    firstCode = ""
                    showMismatchError = true
                    phase = .enter
                }
            case .done:
                break
            }
        }
    }
}

// MARK: - 비밀번호 점 입력 필드

/// 숨겨진 숫자 키패드 입력을 점(●)으로 표시하는 비밀번호 필드입니다.
/// 온보딩 설정과 보호자 모드 잠금 해제에서 함께 사용합니다.
struct PasscodeDotsField: View {
    let length: Int
    @Binding var code: String

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .opacity(0.02)
                .frame(width: 1, height: 1)
                .accessibilityLabel("비밀번호 \(length)자리 입력")

            HStack(spacing: 16) {
                ForEach(0..<length, id: \.self) { index in
                    Circle()
                        .strokeBorder(Color(.systemGray3), lineWidth: 1.5)
                        .background(
                            Circle()
                                .fill(index < code.count ? DreamDrawConstants.brandColor : Color.clear)
                        )
                        .frame(width: 18, height: 18)
                }
            }
            .accessibilityHidden(true)
        }
        .frame(minHeight: DreamDrawConstants.minimumTapSize)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .onAppear { isFocused = true }
        .onChange(of: code) { _, newValue in
            // 숫자만, 지정된 자리수까지만 허용합니다.
            let filtered = String(newValue.filter(\.isNumber).prefix(length))
            if filtered != newValue {
                code = filtered
            }
        }
    }
}

#if DEBUG
#Preview("비밀번호 설정") {
    PasscodeSetupStepView { _ in }
}
#endif
