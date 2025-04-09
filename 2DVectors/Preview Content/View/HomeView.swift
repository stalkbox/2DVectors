//
//  HomeView.swift
//  2DVectors
//
//  Created by Влад Иванов on 14.03.25.
//

import SwiftData
import SwiftUI
import SpriteKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vectors: [Vector]
    @State private var scene: VectorsScene?
    @State private var isPresentingAddVectorView = false
    @State private var isSideMenuShown = false

    var body: some View {
        ZStack {
            if let scene = scene {
                SpriteView(scene: scene)
                    .edgesIgnoringSafeArea(.all)
            } else {
                ProgressView("Загрузка сцены...")
            }

            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // Кнопка для добавления нового вектора
                    Button {
                        isPresentingAddVectorView = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 3, x: 3, y: 3)
                    }
                }
            }
            .padding()
            
            // Side-меню
            SideMenuView(
                vectors: vectors,
                onHighlight: { vector in
                    scene?.highlightVector(vector)
                },
                onDelete: { vector in
                    deleteVector(vector)
                }
            )
        }
        .onChange(of: vectors) {
            scene?.updateVectors(vectors) // Обновление сцены при изменении данных
        }
        .onAppear {
            scene = VectorsScene(vectors: vectors)
        }
        .sheet(isPresented: $isPresentingAddVectorView) {
            AddVectorView()
        }
    }
    
    private func deleteVector(_ vector: Vector) {
        modelContext.delete(vector)
        do {
            try modelContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }
}



#Preview {
    HomeView()
}
