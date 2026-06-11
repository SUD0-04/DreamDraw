//
//  DrawingViewModel.swift
//  DreamDraw
//
//  캔버스 도구 상태, 그림 분석, 저장 요청을 관리합니다.
//

import Combine
import PencilKit
import SwiftUI
import UIKit

@MainActor
final class DrawingViewModel: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    var selectedColor: UIColor = UIColor(red: 0.48, green: 0.37, blue: 0.65, alpha: 1) {
        didSet { objectWillChange.send() }
    }
    var lineWidth: CGFloat = 8 {
        didSet { objectWillChange.send() }
    }
    var isEraserSelected = false {
        didSet { objectWillChange.send() }
    }
    var hasDrawing = false {
        didSet { objectWillChange.send() }
    }
    var isAnalyzing = false {
        didSet { objectWillChange.send() }
    }
    var emotionResult: EmotionResult? {
        didSet { objectWillChange.send() }
    }
    var errorMessage: String? {
        didSet { objectWillChange.send() }
    }

    let canvasView = DreamDrawCanvasView()

    private let colorAnalyzer = ColorAnalyzer()
    private let shapeAnalyzer = ShapeAnalyzer()
    private let emotionInference = EmotionInference()

    init() {
        canvasView.backgroundColor = .systemBackground
        canvasView.drawingPolicy = .anyInput
        updateTool()
    }

    var canAnalyze: Bool {
        hasDrawing && !isAnalyzing
    }

    func drawingDidChange() {
        hasDrawing = !canvasView.drawing.strokes.isEmpty
        if hasDrawing {
            emotionResult = nil
        }
    }

    func selectColor(_ color: UIColor) {
        selectedColor = color
        isEraserSelected = false
        updateTool()
    }

    func updateLineWidth(_ width: CGFloat) {
        lineWidth = width
        isEraserSelected = false
        updateTool()
    }

    func selectEraser() {
        isEraserSelected = true
        updateTool()
    }

    func clearCanvas() {
        canvasView.drawing = PKDrawing()
        hasDrawing = false
        emotionResult = nil
    }

    func analyzeDrawing() async {
        guard canAnalyze else { return }

        isAnalyzing = true
        errorMessage = nil

        let drawing = canvasView.drawing
        hasDrawing = !drawing.strokes.isEmpty
        let image = renderedImage(from: drawing)
        let colorAnalysis = colorAnalyzer.analyze(image: image)
        let shape = shapeAnalyzer.analyze(drawing: drawing)
        // Apple Intelligence를 사용할 수 없으면 내부에서 연구 기반 규칙으로 폴백합니다.
        emotionResult = await emotionInference.inferEmotion(colors: colorAnalysis, shape: shape)

        isAnalyzing = false
    }

    func makeDiaryEntry() -> DiaryEntry? {
        guard let emotionResult else { return nil }
        return DiaryEntry(
            drawingData: canvasView.drawing.dataRepresentation(),
            emotionResult: emotionResult
        )
    }

    private func updateTool() {
        if isEraserSelected {
            canvasView.tool = PKEraserTool(.bitmap)
        } else {
            canvasView.tool = PKInkingTool(.pen, color: selectedColor, width: lineWidth)
        }
    }

    /// 채색 면적 비율(채색 영역 vs 빈 캔버스)을 계산할 수 있도록
    /// 그림 영역이 아닌 캔버스 전체 영역을 기준으로 렌더링합니다.
    private func renderedImage(from drawing: PKDrawing) -> UIImage {
        let canvasBounds = canvasView.bounds.isEmpty
            ? CGRect(x: 0, y: 0, width: 900, height: 700)
            : canvasView.bounds
        return drawing.image(from: canvasBounds, scale: 1)
    }
}
