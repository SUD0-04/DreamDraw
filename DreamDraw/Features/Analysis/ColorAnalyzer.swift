//
//  ColorAnalyzer.swift
//  DreamDraw
//
//  그림 이미지에서 주요 색상 분포, 채색 면적 비율, 밝기·채도를 추출합니다.
//

import UIKit

/// 색상 분석 결과.
///
/// 채색 면적 비율은 PMC (2020) 지적장애 성인 109명 무작위 대조 연구에서
/// 감정 건강 상태의 시각적 지표로 확인된 항목입니다 (근거데이터 문서 3장).
struct ColorAnalysis: Equatable {
    /// 주요 색상 Top 5
    let dominantColors: [MoodColor]
    /// 캔버스 대비 채색 면적 비율 (0.0 ~ 1.0)
    let coloredAreaRatio: Double
    /// 사용된 고유 색상 수 (전체의 2% 이상을 차지하는 색)
    let colorVariety: Int
    /// 채색 영역의 가중 평균 밝기 (0.0 ~ 1.0)
    let averageLightness: Double
    /// 채색 영역의 가중 평균 채도 (0.0 ~ 1.0)
    let averageSaturation: Double

    static let empty = ColorAnalysis(
        dominantColors: [],
        coloredAreaRatio: 0,
        colorVariety: 0,
        averageLightness: 0,
        averageSaturation: 0
    )
}

struct ColorAnalyzer {
    func analyze(image: UIImage, limit: Int = 5) -> ColorAnalysis {
        let resizedImage = image.resizedForAnalysis()
        guard let cgImage = resizedImage.cgImage else {
            return .empty
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return .empty
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var buckets: [String: Int] = [:]
        var coloredCount = 0
        let totalPixelCount = width * height

        stride(from: 0, to: pixels.count, by: bytesPerPixel).forEach { index in
            let alpha = pixels[index + 3]
            guard alpha > 16 else { return }

            let red = pixels[index]
            let green = pixels[index + 1]
            let blue = pixels[index + 2]

            // 거의 흰 배경은 감정 색상 계산에서 제외합니다.
            guard red < 245 || green < 245 || blue < 245 else { return }

            let quantizedRed = Int(red) / 32 * 32
            let quantizedGreen = Int(green) / 32 * 32
            let quantizedBlue = Int(blue) / 32 * 32
            let hex = String(format: "#%02X%02X%02X", quantizedRed, quantizedGreen, quantizedBlue)

            buckets[hex, default: 0] += 1
            coloredCount += 1
        }

        guard coloredCount > 0, totalPixelCount > 0 else {
            return ColorAnalysis(
                dominantColors: [MoodColor(hex: "#7B5EA7", percentage: 1)],
                coloredAreaRatio: 0,
                colorVariety: 0,
                averageLightness: 0.5,
                averageSaturation: 0.5
            )
        }

        let dominantColors = buckets
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { MoodColor(hex: $0.key, percentage: Double($0.value) / Double(coloredCount)) }

        // 버킷 단위로 밝기·채도를 픽셀 수 가중 평균합니다.
        var lightnessSum = 0.0
        var saturationSum = 0.0
        for (hex, count) in buckets {
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0
            UIColor(hex: hex).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            lightnessSum += Double(brightness) * Double(count)
            saturationSum += Double(saturation) * Double(count)
        }

        // 색상 다양성: 채색 픽셀의 2% 이상을 차지하는 고유 색만 셉니다 (노이즈 제외).
        let varietyThreshold = max(1, coloredCount / 50)
        let colorVariety = buckets.values.filter { $0 >= varietyThreshold }.count

        return ColorAnalysis(
            dominantColors: dominantColors,
            coloredAreaRatio: Double(coloredCount) / Double(totalPixelCount),
            colorVariety: colorVariety,
            averageLightness: lightnessSum / Double(coloredCount),
            averageSaturation: saturationSum / Double(coloredCount)
        )
    }
}
