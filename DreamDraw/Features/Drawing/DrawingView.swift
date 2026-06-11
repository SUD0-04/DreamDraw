//
//  DrawingView.swift
//  DreamDraw
//
//  PencilKit으로 감정을 그리는 메인 화면입니다.
//

import Combine
import PencilKit
import SwiftUI

struct DrawingView: View {
    @EnvironmentObject private var diaryStore: DiaryStore
    @StateObject private var viewModel = DrawingViewModel()
    @State private var isResultPresented = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    ToolbarView(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(.regularMaterial)

                    DrawingCanvasRepresentable(viewModel: viewModel)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: proxy.size.width < 500 ? proxy.size.height * 0.55 : proxy.size.height * 0.68
                        )
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        }
                        .padding()
                        .accessibilityLabel("그림을 그리는 캔버스")

                    analyzeButton
                        .padding([.horizontal, .bottom])
                }
            }
            .navigationTitle("DreamDraw")
            .navigationSubtitle("그림으로 말하는 감정 일기")
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $isResultPresented) {
                if let result = viewModel.emotionResult {
                    EmotionResultView(result: result) {
                        if let entry = viewModel.makeDiaryEntry() {
                            diaryStore.addEntry(entry)
                        }
                        isResultPresented = false
                    }
                    .presentationDetents([.medium, .large])
                }
            }
            .alert("분석 오류", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "알 수 없는 오류가 발생했어요.")
            }
            .onChange(of: viewModel.emotionResult) { _, newValue in
                isResultPresented = newValue != nil
            }
        }
    }

    private var analyzeButton: some View {
        Button {
            Task {
                await viewModel.analyzeDrawing()
            }
        } label: {
            HStack {
                if viewModel.isAnalyzing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(viewModel.isAnalyzing ? "분석하고 있어요" : "감정 분석하기")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.borderedProminent)
        .tint(DreamDrawConstants.brandColor)
        .disabled(!viewModel.canAnalyze)
        .accessibilityLabel("감정 분석하기")
    }
}

private struct DrawingCanvasRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: DrawingViewModel

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = viewModel.canvasView
        canvasView.delegate = context.coordinator
        canvasView.didMoveToWindowHandler = { [weak coordinator = context.coordinator, weak canvasView] in
            guard let canvasView else { return }
            coordinator?.installToolPickerIfNeeded(for: canvasView)
        }
        context.coordinator.viewModel = viewModel
        context.coordinator.installToolPickerIfNeeded(for: canvasView)

        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        context.coordinator.viewModel = viewModel
        if let canvasView = uiView as? DreamDrawCanvasView {
            canvasView.didMoveToWindowHandler = { [weak coordinator = context.coordinator, weak canvasView] in
                guard let canvasView else { return }
                coordinator?.installToolPickerIfNeeded(for: canvasView)
            }
        }
        context.coordinator.installToolPickerIfNeeded(for: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        weak var viewModel: DrawingViewModel?
        var toolPicker: PKToolPicker?

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            viewModel?.drawingDidChange()
        }

        func installToolPickerIfNeeded(for canvasView: PKCanvasView) {
            guard UIDevice.current.userInterfaceIdiom == .pad,
                  toolPicker == nil,
                  canvasView.window != nil else { return }

            let toolPicker = PKToolPicker()
            toolPicker.addObserver(canvasView)
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            canvasView.becomeFirstResponder()
            self.toolPicker = toolPicker
        }
    }
}

final class DreamDrawCanvasView: PKCanvasView {
    var didMoveToWindowHandler: (() -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        didMoveToWindowHandler?()
    }
}

#if DEBUG
#Preview("그리기") {
    DrawingView()
        .environmentObject(DiaryStore(previewEntries: []))
}
#endif
