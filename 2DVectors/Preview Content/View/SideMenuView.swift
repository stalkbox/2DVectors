//
//  SideMenuView.swift
//  2DVectors
//
//  Created by Влад Иванов on 18.03.25.
//

import SwiftUI

struct SideMenuView: View {
    var vectors: [Vector]
    var onHighlight: (Vector) -> Void // Замыкание для подсветки
    var onDelete: (Vector) -> Void // Замыкание для удаления
    
    @State private var isSideMenuShown: Bool = false
    
    var body: some View {
        GeometryReader { proxy in
            HStack {
                VStack(alignment: .leading) {
                    Text("Вектора")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(10)
                        .scaleEffect(isSideMenuShown ? 1 : 0)
                    
                    ScrollView {
                        ForEach(vectors, id: \.id) { vector in
                            VectorRowView(vector: vector, onHighlight: onHighlight, onDelete: onDelete)
                                .padding(.horizontal, 5)
                                .opacity(isSideMenuShown ? 1 : 0)
                        }
                    }
                }
                .frame(width: isSideMenuShown ? proxy.size.width / 3 : 0, height: proxy.size.height)
                .background(.ultraThickMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 5)
                
                buttonMenu()
            }
        }
    }
    
    @ViewBuilder
    private func buttonMenu() -> some View {
        VStack {
            Button(action: {
                withAnimation(.snappy) {
                    isSideMenuShown.toggle()
                }
            }) {
                Image(systemName: isSideMenuShown ? "xmark" : "line.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(isSideMenuShown ? .gray : .blue)
                    .clipShape(Circle())
                    .shadow(radius: 3, x: 3, y: 3)
                    .padding(.vertical)
                    .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating))
            }
            
            Spacer()
        }
    }
}

#Preview {
    HomeView()
}
