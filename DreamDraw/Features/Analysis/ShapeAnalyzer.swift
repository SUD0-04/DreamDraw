//
//  ShapeAnalyzer.swift
//  DreamDraw
//
//  PencilKit 선의 압력·속도·길이·불규칙성으로 그림의 패턴을 요약합니다.
//
//  근거: ScienceDirect (2024) 손그림 선의 17가지 감정 특성 연구,
//  Nature Scientific Reports (2024) 'Drawing as a window to emotion',
//  USPTO US9229543 스타일러스 감정 추론 특허 (근거데이터 문서 2장).
//

import PencilKit

struct ShapeAnalysis: Codable, Equatable {
    /// 총 획 수 — 많으면 불안 또는 높은 에너지, 적으면 무기력·우울 가능성
    let strokeCount: Int
    let pointCount: Int
    let drawingBoundsArea: Double
    /// 평균 필압 — 강함+빠름은 흥분·각성, 약함+느림은 차분·무기력 (손가락 입력은 1.0 고정)
    let averageForce: Double
    /// 평균 획 속도 (pt/초) — 매우 빠르면 충동·불안, 매우 느리면 우울·피로
    let averageSpeed: Double
    /// 평균 획 길이 (pt) — 짧고 불규칙하면 불안·긴장, 길고 부드러우면 안정
    let averageStrokeLength: Double
    /// 획 불규칙성 점수 (0~1) — 방향 전환 빈도와 획 길이 편차의 조합
    let irregularityScore: Double

    var isFastPaced: Bool { averageSpeed > 500 }
    var isSlowPaced: Bool { averageSpeed > 0 && averageSpeed < 120 }
    var isIrregular: Bool { irregularityScore > 0.6 }

    var description: String {
        if strokeCount == 0 {
            return "아직 선이 거의 없어 감정 신호가 약합니다."
        }

        if isFastPaced && isIrregular {
            return "짧고 빠른 선이 반복되어 긴장하거나 들떠 있는 상태로 보입니다."
        }

        if strokeCount > 18 || pointCount > 900 {
            return "선이 많고 움직임이 활발해 에너지가 크게 느껴집니다."
        }

        if isSlowPaced && strokeCount <= 5 {
            return "선이 느리고 적어 에너지가 낮은 상태일 수 있습니다."
        }

        if drawingBoundsArea < 18_000 {
            return "작고 조심스러운 형태가 중심에 모여 있습니다."
        }

        if averageStrokeLength > 120 && !isIrregular {
            return "길고 부드러운 곡선이 이어져 안정감이 느껴집니다."
        }

        return "선이 비교적 안정적이고 부드럽게 이어집니다."
    }
}

struct ShapeAnalyzer {
    func analyze(drawing: PKDrawing) -> ShapeAnalysis {
        var pointCount = 0
        var forceSum = 0.0
        var forceCount = 0
        var strokeLengths: [Double] = []
        var strokeSpeeds: [Double] = []
        var directionChanges: [Double] = []

        for stroke in drawing.strokes {
            let points = Array(stroke.path)
            pointCount += points.count
            guard points.count > 1 else {
                strokeLengths.append(0)
                continue
            }

            var length = 0.0
            var previousAngle: Double?

            for index in 1..<points.count {
                let from = points[index - 1].location
                let to = points[index].location
                let dx = Double(to.x - from.x)
                let dy = Double(to.y - from.y)
                let segment = (dx * dx + dy * dy).squareRoot()
                length += segment

                forceSum += Double(points[index].force)
                forceCount += 1

                // 1pt 미만 이동은 손떨림 노이즈로 보고 방향 계산에서 제외합니다.
                guard segment > 1 else { continue }
                let angle = atan2(dy, dx)
                if let previousAngle {
                    var delta = abs(angle - previousAngle)
                    if delta > .pi { delta = 2 * .pi - delta }
                    directionChanges.append(delta)
                }
                previousAngle = angle
            }

            strokeLengths.append(length)

            let duration = points[points.count - 1].timeOffset - points[0].timeOffset
            if duration > 0.01 {
                strokeSpeeds.append(length / duration)
            }
        }

        let bounds = drawing.bounds
        let area = max(0, bounds.width * bounds.height)

        return ShapeAnalysis(
            strokeCount: drawing.strokes.count,
            pointCount: pointCount,
            drawingBoundsArea: area,
            averageForce: forceCount > 0 ? forceSum / Double(forceCount) : 0,
            averageSpeed: average(of: strokeSpeeds),
            averageStrokeLength: average(of: strokeLengths),
            irregularityScore: irregularityScore(strokeLengths: strokeLengths, directionChanges: directionChanges)
        )
    }

    private func average(of values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    /// 방향 전환의 급격함(60%)과 획 길이 편차(40%)를 조합한 0~1 점수입니다.
    /// 근거데이터 문서: "기울기 변화 급격함 → 감정적 고조", "짧고 불규칙한 획 → 불안·긴장".
    private func irregularityScore(strokeLengths: [Double], directionChanges: [Double]) -> Double {
        let directionComponent: Double
        if directionChanges.isEmpty {
            directionComponent = 0
        } else {
            // 평균 방향 변화량을 90도 기준으로 정규화합니다.
            directionComponent = min(1, average(of: directionChanges) / (.pi / 2))
        }

        let lengthComponent: Double
        let meaningfulLengths = strokeLengths.filter { $0 > 0 }
        if meaningfulLengths.count > 1 {
            let mean = average(of: meaningfulLengths)
            let variance = meaningfulLengths.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(meaningfulLengths.count)
            let coefficientOfVariation = mean > 0 ? variance.squareRoot() / mean : 0
            lengthComponent = min(1, coefficientOfVariation / 1.2)
        } else {
            lengthComponent = 0
        }

        return min(1, directionComponent * 0.6 + lengthComponent * 0.4)
    }
}
