//
//  AddVectorView.swift
//  2DVectors
//
//  Created by Влад Иванов on 14.03.25.
//

import SwiftUI

struct AddVectorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    @State private var startX: CGFloat = 0
    @State private var startY: CGFloat = 0
    @State private var endX: CGFloat = 0
    @State private var endY: CGFloat = 0
    
    @State private var errorMessage: String? // Сообщение об ошибке
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Добавление вектора")
                .font(.title)
                .foregroundStyle(.primary.opacity(0.3))
                .padding(.bottom, 20)
            
            // Ввод координат
            VStack(spacing: 10) {
                Text("Начальная точка")
                    .font(.headline)
                HStack {
                    Text("X:")
                    TextField("X", value: $startX, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .padding(.trailing, 10)
                    
                    Text("Y:")
                        .padding(.leading, 10)
                    TextField("Y", value: $startY, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
            }
            
            VStack(spacing: 10) {
                Text("Конечная точка")
                    .font(.headline)
                HStack {
                    Text("X:")
                    TextField("X", value: $endX, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .padding(.trailing, 10)
                    
                    Text("Y:")
                        .padding(.leading, 10)
                    TextField("Y", value: $endY, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
            }
            
            // Кнопка добавления
            Button {
                saveVector()
            } label: {
                Text("Добавить")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .shadow(radius: 3, x: 0, y: 5)
            }
            .padding(.top, 20)
            
            // Сообщение об ошибке
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
            }
        }
        .padding(30)
    }
    
    private func saveVector() {
        if validateInput() {
            let newVector = Vector(startPoint: CGPoint(x: startX, y: startY), endPoint: CGPoint(x: endX, y: endY))
            
            modelContext.insert(newVector)
            do {
                try modelContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func validateInput() -> Bool {
        withAnimation {
            if startX < 0 || startX > 1200 || startY < 0 || startY > 1200 ||
                endX < 0 || endX > 1200 || endY < 0 || endY > 1200 {
                errorMessage = "Все координаты должны находиться в диапазоне от 0 до 1200."
                return false
            }
            errorMessage = nil
            return true
        }
    }
}


#Preview {
    AddVectorView()
}
