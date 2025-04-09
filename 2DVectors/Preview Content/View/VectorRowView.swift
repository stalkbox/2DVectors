//
//  VectorRowView.swift
//  2DVectors
//
//  Created by Влад Иванов on 18.03.25.
//

import SwiftUI

struct VectorRowView: View {
    var vector: Vector
    var onHighlight: (Vector) -> Void // Замыкание для подсветки
    var onDelete: (Vector) -> Void // Для удаления вектора

    @State private var offset: CGFloat = 0 // Сдвиг строки
    @State private var isHighlighted: Bool = false // Состояние подсветки

    private let buttonWidth: CGFloat = 40 // Ширина и высота кнопки удаления
    private let paddingButton: CGFloat = 10

    var body: some View {
        ZStack {
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        onDelete(vector) // Удаление вектора
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: buttonWidth, height: buttonWidth) // Устанавливаем ширину и высоту кнопки равными buttonWidth
                        .background(Color.red)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .offset(x: offset < -buttonWidth / 2 ? 0 : buttonWidth + paddingButton) // Логика выезда кнопки
            }

            // Основное содержимое строки
            VStack(alignment: .leading, spacing: 4) {
                Text(getLabelVector(vector))
                    .font(.caption2)
                    .foregroundColor(.primary)

                Text(String(format: "Длина: %.2f", vector.length))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.primary.opacity(isHighlighted ? 0.3 : 0.1))
                    .shadow(color: .black, radius: 3, x: 0, y: 2)
            )
            .offset(x: offset) // Сдвиг строки
            .simultaneousGesture(dragGesture())
            .onTapGesture {
                withAnimation {
                    onHighlight(vector)
                    isHighlighted = true
                }
                withAnimation(.easeInOut(duration: 0.3).delay(1)) {
                    isHighlighted = false
                }
            }
        }
    }

    private func dragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                withAnimation {
                    // Ограничиваем движение строки
                    if value.translation.width < 0 {
                        offset = max(value.translation.width, -(buttonWidth + paddingButton))
                    } else {
                        offset = min(value.translation.width, 0) // Блокируем свайп вправо
                    }
                }
            }
            .onEnded { _ in
                withAnimation {
                    // Фиксируем положение строки в зависимости от порога свайпа
                    offset = offset <= -buttonWidth / 2 ? -(buttonWidth + paddingButton) : 0
                }
            }
    }

    private func getLabelVector(_ vector: Vector) -> String {
        return "(\(Int(vector.startX)); \(Int(vector.startY))) -> (\(Int(vector.endX)); \(Int(vector.endY)))"
    }
}

#Preview {
    let vector = Vector(startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 100, y: 120))
    
    VectorRowView(vector: vector, onHighlight: {_ in }, onDelete: {_ in })
}
