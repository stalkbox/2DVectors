//
//  Vector.swift
//  2DVectors
//
//  Created by Влад Иванов on 14.03.25.
//

import SwiftData
import SwiftUI

@Model
class Vector {
    var id: UUID
    var startX: Double
    var startY: Double
    var endX: Double
    var endY: Double
    
    @Transient var startPoint: CGPoint {
        get { CGPoint(x: startX, y: startY) }
        set {
            startX = newValue.x
            startY = newValue.y
        }
    }

    @Transient var endPoint: CGPoint {
        get { CGPoint(x: endX, y: endY) }
        set {
            endX = newValue.x
            endY = newValue.y
        }
    }
    
    @Transient var length: Double {
        let dx = endX - startX
        let dy = endY - startY
        return sqrt(dx * dx + dy * dy)
    }
    
    init(startPoint: CGPoint, endPoint: CGPoint) {
        self.id = UUID()
        self.startX = startPoint.x
        self.startY = startPoint.y
        self.endX = endPoint.x
        self.endY = endPoint.y
    }
}
