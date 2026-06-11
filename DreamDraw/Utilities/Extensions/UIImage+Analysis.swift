//
//  UIImage+Analysis.swift
//  DreamDraw
//
//  PencilKit 이미지를 분석 가능한 픽셀 버퍼로 축소합니다.
//

import UIKit

extension UIImage {
    func resizedForAnalysis(maxDimension: CGFloat = 160) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return self }

        let scale = maxDimension / longestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
