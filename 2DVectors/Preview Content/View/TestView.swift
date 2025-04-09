//
//  TestView.swift
//  2DVectors
//
//  Created by Влад Иванов on 14.03.25.
//

import SpriteKit
import SwiftUI

class CanvasScene: SKScene {
    private var canvas: SKNode!
    private var lastPanLocation: CGPoint?

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        // Create "canvas" as SKNode
        canvas = SKNode()
        canvas.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(canvas)
        
        // Add example content
        let background = SKSpriteNode(color: .lightGray, size: CGSize(width: 200, height: 1000))
        background.position = .zero
        canvas.addChild(background)
        
        // Draw first line
        let line1Path = CGMutablePath()
        line1Path.move(to: CGPoint(x: -50, y: 0))
        line1Path.addLine(to: CGPoint(x: 50, y: 100))
        let line1 = SKShapeNode(path: line1Path)
        line1.strokeColor = .red
        line1.lineWidth = 2
        canvas.addChild(line1)
        
        // Draw second line
        let line2Path = CGMutablePath()
        line2Path.move(to: CGPoint(x: 0, y: -50))
        line2Path.addLine(to: CGPoint(x: 100, y: 50))
        let line2 = SKShapeNode(path: line2Path)
        line2.strokeColor = .blue
        line2.lineWidth = 2
        canvas.addChild(line2)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        let currentLocation = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)

        let deltaX = currentLocation.x - previousLocation.x
        let deltaY = currentLocation.y - previousLocation.y

        // Вычисляем новое положение
        let newCanvasPosition = CGPoint(
            x: canvas.position.x + deltaX,
            y: canvas.position.y + deltaY
        )

        // Ограничиваем перемещение рамками сцены
        let clampedX = max(size.width - 2000 / 2, min(newCanvasPosition.x, 2000 / 2))
        let clampedY = max(size.height - 1000 / 2, min(newCanvasPosition.y, 1000 / 2))

        canvas.position = CGPoint(x: clampedX, y: clampedY)
    }
}

struct CanvasView: View {
    @State private var scene = CanvasScene(size: CGSize(width: 500, height: 500))
    
    var body: some View {
        SpriteView(scene: scene)
    }
}

#Preview {
    CanvasView()
}
