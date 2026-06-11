//
//  ToolbarView.swift
//  DreamDraw
//
//  색상, 굵기, 지우개, 전체 지우기 도구를 제공합니다.
//

import Combine
import SwiftUI
import UIKit

struct ToolbarView: View {
    @ObservedObject var viewModel: DrawingViewModel

    private let colors: [UIColor] = [
        UIColor(red: 0.48, green: 0.37, blue: 0.65, alpha: 1),
        UIColor(red: 0.95, green: 0.66, blue: 0.20, alpha: 1),
        UIColor(red: 0.28, green: 0.48, blue: 0.76, alpha: 1),
        UIColor(red: 0.31, green: 0.63, blue: 0.58, alpha: 1),
        UIColor(red: 0.86, green: 0.32, blue: 0.28, alpha: 1),
        .label
    ]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    Button {
                        viewModel.selectColor(color)
                    } label: {
                        Circle()
                            .fill(Color(uiColor: color))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Circle()
                                    .stroke(
                                        viewModel.selectedColor == color && !viewModel.isEraserSelected
                                            ? DreamDrawConstants.brandColor
                                            : Color.clear,
                                        lineWidth: 3
                                    )
                            }
                            .frame(width: DreamDrawConstants.minimumTapSize, height: DreamDrawConstants.minimumTapSize)
                    }
                    .accessibilityLabel("\(color.hexString) 색상 선택")
                }

                Spacer()

                Button {
                    viewModel.selectEraser()
                } label: {
                    Image(systemName: "eraser")
                        .frame(width: DreamDrawConstants.minimumTapSize, height: DreamDrawConstants.minimumTapSize)
                }
                .buttonStyle(.bordered)
                .tint(viewModel.isEraserSelected ? DreamDrawConstants.brandColor : Color.secondary)
                .accessibilityLabel("지우개")

                Button(role: .destructive) {
                    viewModel.clearCanvas()
                } label: {
                    Image(systemName: "trash")
                        .frame(width: DreamDrawConstants.minimumTapSize, height: DreamDrawConstants.minimumTapSize)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("전체 지우기")
            }

            HStack {
                Image(systemName: "pencil.tip")
                    .foregroundStyle(.secondary)
                Slider(
                    value: Binding(
                        get: { Double(viewModel.lineWidth) },
                        set: { viewModel.updateLineWidth(CGFloat($0)) }
                    ),
                    in: 3...24,
                    step: 1
                )
                .accessibilityLabel("선 굵기")

                Text("\(Int(viewModel.lineWidth))")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 32, alignment: .trailing)
            }
        }
    }
}

#if DEBUG
#Preview {
    ToolbarView(viewModel: DrawingViewModel())
        .padding()
}
#endif
