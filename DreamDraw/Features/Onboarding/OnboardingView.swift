//
//  OnboardingView.swift
//  DreamDraw
//
//  첫 실행 시 환영 → 아동 이름 → 보호자 비밀번호 순서로 안내하는 온보딩 화면입니다.
//

import Combine
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettingsStore

    private enum Step {
        case welcome
        case childName
        case passcode
    }

    @State private var step: Step = .welcome
    @State private var childName = ""

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch step {
                case .welcome:
                    WelcomeStepView {
                        advance(to: .childName)
                    }
                case .childName:
                    ChildNameStepView(childName: $childName) {
                        advance(to: .passcode)
                    }
                case .passcode:
                    PasscodeSetupStepView { passcode in
                        completeOnboarding(passcode: passcode)
                    }
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            stepIndicator
                .padding(.bottom, 12)
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach([Step.welcome, .childName, .passcode], id: \.self) { item in
                Circle()
                    .fill(item == step ? DreamDrawConstants.brandColor : Color(.systemFill))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityHidden(true)
    }

    private func advance(to next: Step) {
        withAnimation(.easeInOut(duration: 0.3)) {
            step = next
        }
    }

    private func completeOnboarding(passcode: String?) {
        settings.childName = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.setGuardianPasscode(passcode)
        withAnimation(.easeInOut(duration: 0.35)) {
            settings.hasCompletedOnboarding = true
        }
    }
}

// MARK: - 1단계: 환영 및 기능 소개

private struct WelcomeStepView: View {
    let onNext: () -> Void

    @State private var isSourcesPresented = false

    private struct Feature: Identifiable {
        let id = UUID()
        let symbolName: String
        let title: String
        let detail: String
    }

    private let features: [Feature] = [
        Feature(
            symbolName: "pencil.and.outline",
            title: "자유롭게 그리기",
            detail: "말 대신 그림으로 오늘의 감정을 표현해요. Apple Pencil과 손가락 모두 사용할 수 있어요."
        ),
        Feature(
            symbolName: "sparkles",
            title: "감정 분석",
            detail: "Apple Intelligence가 색과 선을 분석해 감정을 따뜻하게 읽어줘요. 모든 분석은 기기 안에서만 이뤄져요."
        ),
        Feature(
            symbolName: "calendar",
            title: "감정 달력",
            detail: "하루하루의 감정이 색으로 모여 한 달의 마음 흐름을 한눈에 볼 수 있어요."
        ),
        Feature(
            symbolName: "person.2",
            title: "보호자 요약",
            detail: "보호자와 활동보조인이 최근 감정 흐름과 주의 신호를 확인할 수 있어요."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(spacing: 14) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(DreamDrawConstants.brandColor)
                            .accessibilityHidden(true)

                        Text("DreamDraw에 오신 것을\n환영합니다")
                            .font(.largeTitle.weight(.bold))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 48)

                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(features) { feature in
                            HStack(alignment: .top, spacing: 16) {
                                Image(systemName: feature.symbolName)
                                    .font(.title2)
                                    .foregroundStyle(DreamDrawConstants.brandColor)
                                    .frame(width: DreamDrawConstants.minimumTapSize, height: DreamDrawConstants.minimumTapSize)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(feature.title)
                                        .font(.headline)
                                    Text(feature.detail)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }

                    disclaimer
                }
                .padding(.horizontal, 28)
            }

            OnboardingNextButton(title: "다음", action: onNext)
        }
        .sheet(isPresented: $isSourcesPresented) {
            ResearchSourcesView()
        }
    }

    /// Apple Watch 심전도 앱의 고지처럼, 참고용 도구임을 안내합니다.
    private var disclaimer: some View {
        VStack(alignment: .center, spacing: 10) {
            Image(systemName: "heart.text.square")
                .font(.title3)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("DreamDraw는 발달장애인의 비언어적 감정 표현을 돕기 위해 설계된 참고용 보조 도구입니다. 감정 분석 결과는 학술 연구를 바탕으로 하지만 전문적인 심리·의료 진단이나 치료를 대체하지 않으며, 보호자의 관찰과 맥락 정보를 함께 고려해 해석해야 합니다.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("참고 연구 출처 보기") {
                isSourcesPresented = true
            }
            .font(.footnote.weight(.semibold))
            .frame(minHeight: DreamDrawConstants.minimumTapSize)
            .accessibilityLabel("참고 연구 출처 보기")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - 2단계: 아동 이름 설정

private struct ChildNameStepView: View {
    @Binding var childName: String
    let onNext: () -> Void

    @FocusState private var isNameFieldFocused: Bool

    private var trimmedName: String {
        childName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 56))
                        .foregroundStyle(DreamDrawConstants.brandColor)
                        .accessibilityHidden(true)

                    Text("아이의 이름을 알려주세요")
                        .font(.title.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text(trimmedName.isEmpty
                         ? "이름은 그리기 화면 위쪽에 표시돼요."
                         : "그리기 화면에 '\(trimmedName)의 DreamDraw'로 표시돼요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    TextField("이름", text: $childName)
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .focused($isNameFieldFocused)
                        .submitLabel(.done)
                        .onChange(of: childName) { _, newValue in
                            // 표시 공간을 고려해 12자로 제한합니다.
                            if newValue.count > 12 {
                                childName = String(newValue.prefix(12))
                            }
                        }
                        .padding(.top, 10)
                        .accessibilityLabel("아이 이름 입력")
                }
                .padding(.horizontal, 28)
                .padding(.top, 72)
            }

            OnboardingNextButton(title: "다음", isEnabled: !trimmedName.isEmpty, action: onNext)
        }
        .onAppear { isNameFieldFocused = true }
    }
}

// MARK: - 공용 하단 버튼

struct OnboardingNextButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.borderedProminent)
        .tint(DreamDrawConstants.brandColor)
        .disabled(!isEnabled)
        .padding(.horizontal, 28)
        .padding(.bottom, 16)
        .accessibilityLabel(title)
    }
}

#if DEBUG
#Preview("온보딩") {
    OnboardingView()
        .environmentObject(AppSettingsStore())
}
#endif
