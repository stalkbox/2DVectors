//
//  GameScene.swift
//  2DVectors
//
//  Created by Влад Иванов on 14.03.25.
//

import SpriteKit
import UIKit

class VectorsScene: SKScene {
    private var cameraNode: SKCameraNode!
    private var vectors: [Vector] = []
    private var editingVector: Vector? // Вектор, который редактируется
    private var editingStartPoint: Bool? // true - начальная точка, false - конечная, nil - весь вектор
    private var longPressStartTime: TimeInterval? // Время начала long-press
    private var vectorColors: [UUID: UIColor] = [:]
    
    init(vectors: [Vector]) {
        self.vectors = vectors
        super.init(size: CGSize(width: 1200, height: 1200))
        backgroundColor = .white
        self.scaleMode = .aspectFill
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        setupCamera()
        addGrid(spacing: 100)
        addAxisLabels(spacing: 100)
        
        updateVectors(self.vectors)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        longPressStartTime = touch.timestamp

        // Проверяем, попало ли касание на вектор или его точки
        if let (isPoint, isStartPoint) = vectors.compactMap({ detectHit(vector: $0, at: location) }).first {
            editingVector = vectors.first(where: { detectHit(vector: $0, at: location) != nil })
            editingStartPoint = isPoint ? isStartPoint : nil // Устанавливаем, что редактируется
            return
        }

        // Если касание вне векторов
        editingVector = nil
        editingStartPoint = nil
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if let vector = editingVector {
            // Обрабатываем редактирование вектора
            handleEditingVector(touch: touch, vector: vector, location: location)
        } else {
            // Вызываем метод moveCamera для обработки перемещения камеры
            let translation = CGPoint(
                x: touch.previousLocation(in: self).x - touch.location(in: self).x,
                y: touch.previousLocation(in: self).y - touch.location(in: self).y
            )
            moveCamera(by: translation)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelEditing()
    }
    
    // Обновление массива векторов и перерисовка
    func updateVectors(_ newVectors: [Vector]) {
        // Обновляем массив векторов
        self.vectors = newVectors
        removeAllVectors() // Удаляем старые элементы

        for vector in vectors {
            // Если id отсутствует в vectorColors, добавляем новый цвет
            if vectorColors[vector.id] == nil {
                let color = UIColor.random()
                vectorColors[vector.id] = color
            }

            // Используем существующий или только что добавленный цвет
            let color = vectorColors[vector.id]!
            drawVector(vector, color: color)
        }
        
        drawAllRightAngleIndicators()
    }
    
    // Подсветка вектора
    func highlightVector(_ vector: Vector, highlightWidth: CGFloat = 6, duration: TimeInterval = 1.0) {
        // Ищем узел вектора по имени
        if let vectorNode = children.first(where: { $0.name == "vector-\(vector.id)" }) as? SKShapeNode {
            // Увеличиваем толщину линии
            let originalWidth = vectorNode.lineWidth
            vectorNode.lineWidth = highlightWidth

            // Возвращаем исходную толщину через указанный промежуток времени
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                vectorNode.lineWidth = originalWidth
            }
        }
    }
}

// MARK: - Редактирование векторов
extension VectorsScene {
    // Обрабатывает long-press и редактирование объекта
    private func handleEditingVector(touch: UITouch, vector: Vector, location: CGPoint) {
        guard let startTime = longPressStartTime else { return }
        let longPressActive = touch.timestamp - startTime > 0.5

        if !longPressActive && !isTouchWithinBounds(touch: touch, vector: vector) {
            // Если long-press ещё не активен и касание вышло за границы, завершаем редактирование
            cancelEditing()
            return
        }

        if longPressActive {
            // Выполняем редактирование (перемещение точки или вектора)
            moveEditingVector(touch: touch, vector: vector, location: location)
        }
    }
    
    // Определяет, находится ли точка в заданном радиусе
    private func isWithinThreshold(point1: CGPoint, point2: CGPoint, threshold: CGFloat = 30.0) -> Bool {
        return hypot(point1.x - point2.x, point1.y - point2.y) < threshold
    }

    // Проверяет, попадает ли касание на редактируемую точку или вектор
    private func isTouchWithinBounds(touch: UITouch, vector: Vector) -> Bool {
        let location = touch.location(in: self)
        return detectHit(vector: vector, at: location) != nil
    }

    // Логика перемещения вектора
    private func moveEditingVector(touch: UITouch, vector: Vector, location: CGPoint) {
        let previousLocation = touch.previousLocation(in: self)

        if let isEditingStart = editingStartPoint {
            // Перемещаем начальную или конечную точку
            moveVectorPoint(vector: vector, location: location, isEditingStart: isEditingStart)
        } else {
            // Перемещаем весь вектор целиком
            moveEntireVector(vector: vector, translation: CGPoint(
                x: location.x - previousLocation.x,
                y: location.y - previousLocation.y
            ))
        }
        
        // Проверяем и удаляем индикаторы
        validateAndRemoveIndicators(for: vector)
        // Перерисовываем редактируемый вектор
        redrawVector(vector)
    }
    
    // Перемещение точки вектора
    private func moveVectorPoint(vector: Vector, location: CGPoint, isEditingStart: Bool) {
        var movingPoint = isEditingStart ? vector.startPoint : vector.endPoint
        movingPoint = location

        // Ограничиваем точку в пределах полотна
        movingPoint = clampToCanvas(movingPoint)

        // Применяем "прилипание"
        applySnapToVector(vector: vector, movingPoint: &movingPoint, isStartPoint: isEditingStart)

        // Обновляем координаты начальной или конечной точки
        if isEditingStart {
            vector.startPoint = movingPoint
        } else {
            vector.endPoint = movingPoint
        }
    }

    // Перемещение линии вектора
    private func moveEntireVector(vector: Vector, translation: CGPoint) {
        // Рассчитываем новые позиции для начальной и конечной точек
        let newStartPoint = CGPoint(
            x: vector.startPoint.x + translation.x,
            y: vector.startPoint.y + translation.y
        )
        let newEndPoint = CGPoint(
            x: vector.endPoint.x + translation.x,
            y: vector.endPoint.y + translation.y
        )

        // Ограничиваем новые позиции в пределах полотна
        let clampedStartPoint = clampToCanvas(newStartPoint)
        let clampedEndPoint = clampToCanvas(newEndPoint)

        // Проверяем, упирается ли хотя бы одна из точек в границу
        if newStartPoint != clampedStartPoint || newEndPoint != clampedEndPoint {
            // Если одна из точек упёрлась в границу, движение останавливается
            return
        }

        // Если обе точки могут двигаться, обновляем их положения
        vector.startPoint = newStartPoint
        vector.endPoint = newEndPoint
    }
    
    // Универсальная проверка: попадание на начальную/конечную точку или сам вектор
    private func detectHit(vector: Vector, at point: CGPoint) -> (isPoint: Bool, isStartPoint: Bool?)? {
        // Проверяем попадание на начальную точку
        if isWithinThreshold(point1: vector.startPoint, point2: point) {
            return (isPoint: true, isStartPoint: true)
        }
        // Проверяем попадание на конечную точку
        if isWithinThreshold(point1: vector.endPoint, point2: point) {
            return (isPoint: true, isStartPoint: false)
        }
        // Проверяем попадание на сам вектор
        if isPointOnVector(vector: vector, point: point) {
            return (isPoint: false, isStartPoint: nil)
        }
        return nil // Если касание не попало никуда
    }

    // Проверка на попадание на вектор
    private func isPointOnVector(vector: Vector, point: CGPoint) -> Bool {
        let dx = vector.endPoint.x - vector.startPoint.x
        let dy = vector.endPoint.y - vector.startPoint.y
        let lengthSquared = dx * dx + dy * dy

        guard lengthSquared > 0 else { return false } // Если вектор имеет нулевую длину

        // Вычисляем ближайшую точку на векторе
        let t = max(0, min(1, ((point.x - vector.startPoint.x) * dx + (point.y - vector.startPoint.y) * dy) / lengthSquared))
        let closestPoint = CGPoint(
            x: vector.startPoint.x + t * dx,
            y: vector.startPoint.y + t * dy
        )
        return isWithinThreshold(point1: closestPoint, point2: point) // Проверяем попадание на ближайшую точку
    }

    // Поиск общей точки
    private func findCommonPoint(between vector1: Vector, and vector2: Vector) -> CGPoint? {
        if vector1.startPoint == vector2.startPoint || vector1.startPoint == vector2.endPoint {
            return vector1.startPoint
        } else if vector1.endPoint == vector2.startPoint || vector1.endPoint == vector2.endPoint {
            return vector1.endPoint
        }
        return nil
    }
    
    // Ограничивает координаты точки, чтобы она оставалась в допустимых пределах
    private func clampToCanvas(_ point: CGPoint) -> CGPoint {
        let minX: CGFloat = 0
        let maxX: CGFloat = size.width
        let minY: CGFloat = 0
        let maxY: CGFloat = size.height

        return CGPoint(
            x: max(minX, min(maxX, point.x)),
            y: max(minY, min(maxY, point.y))
        )
    }
    
    // Завершение редактирования вектора
    private func cancelEditing() {
        editingVector = nil
        editingStartPoint = nil
        longPressStartTime = nil
    }
}

// MARK: - Логика "прилипания"
extension VectorsScene {
    // Отвечает за логику прилипаний
    private func applySnapToVector(vector: Vector, movingPoint: inout CGPoint, isStartPoint: Bool) {
        let snapDistance: CGFloat = 20.0

        // Проверка прилипания к началу или концу текущего вектора
        let originalPoint = isStartPoint ? vector.endPoint : vector.startPoint

        if abs(movingPoint.y - originalPoint.y) < snapDistance {
            movingPoint.y = originalPoint.y
        }
        if abs(movingPoint.x - originalPoint.x) < snapDistance {
            movingPoint.x = originalPoint.x
        }

        // Проверка прилипания к другим векторам
        for otherVector in vectors where otherVector !== vector {
            // Создаём массив точек для проверки
            let snapPoints = [otherVector.startPoint, otherVector.endPoint]

            // Находим ближайшую точку прилипания
            if let snapPoint = snapPoints.first(where: { hypot(movingPoint.x - $0.x, movingPoint.y - $0.y) < snapDistance }) {
                movingPoint = snapPoint
                return
            }

            // Проверяем на совпадение с началом или концом текущего вектора
            let currentPoints = [vector.startPoint, vector.endPoint]
            
            if let fixedPoint = currentPoints.first(where: {
                hypot($0.x - otherVector.startPoint.x, $0.y - otherVector.startPoint.y) < snapDistance ||
                hypot($0.x - otherVector.endPoint.x, $0.y - otherVector.endPoint.y) < snapDistance
            }) {
                // Применяем корректировки по углу
                adjustToRightAngle(referenceVector: otherVector, fixedPoint: fixedPoint, movingPoint: &movingPoint, isStartPoint: isStartPoint)
                
                if isRightAngle(vector1: vector, vector2: otherVector, at: fixedPoint) {
                    drawRightAngleIndicator(at: fixedPoint, vector1: vector, vector2: otherVector)
                }
            }
        }
    }
    
    // Корректировка положения редактируемой точки, чтобы угол стал прямым
    private func adjustToRightAngle(referenceVector: Vector, fixedPoint: CGPoint, movingPoint: inout CGPoint, isStartPoint: Bool) {
        let dx1 = referenceVector.endPoint.x - referenceVector.startPoint.x
        let dy1 = referenceVector.endPoint.y - referenceVector.startPoint.y
        let dx2 = movingPoint.x - fixedPoint.x
        let dy2 = movingPoint.y - fixedPoint.y

        // Проверяем угол между векторами
        let dotProduct = dx1 * dx2 + dy1 * dy2
        let magnitude1 = hypot(dx1, dy1)
        let magnitude2 = hypot(dx2, dy2)
        let cosTheta = dotProduct / (magnitude1 * magnitude2)

        // Если угол близок к 90 градусам
        if abs(cosTheta) < 0.1 { // cos(90 градусов) ≈ 0
            let length = hypot(dx2, dy2)

            // Определяем направление на основе исходного движения точки
            let directionX = movingPoint.x >= fixedPoint.x ? 1.0 : -1.0
            let directionY = movingPoint.y >= fixedPoint.y ? 1.0 : -1.0

            let angle = atan2(dy1, dx1) + (isStartPoint ? .pi / 2 : -.pi / 2)

            // Корректируем позицию редактируемой точки
            movingPoint.x = fixedPoint.x + directionX * abs(cos(angle) * length)
            movingPoint.y = fixedPoint.y + directionY * abs(sin(angle) * length)
        }
    }
    
    // Распознавание прямого угла между двумя векторами
    private func isRightAngle(vector1: Vector, vector2: Vector, at point: CGPoint) -> Bool {
        let dx1 = vector1.endPoint.x - vector1.startPoint.x
        let dy1 = vector1.endPoint.y - vector1.startPoint.y
        let dx2 = vector2.endPoint.x - vector2.startPoint.x
        let dy2 = vector2.endPoint.y - vector2.startPoint.y

        // Определяем угол между векторами
        let dotProduct = dx1 * dx2 + dy1 * dy2
        let magnitude1 = hypot(dx1, dy1)
        let magnitude2 = hypot(dx2, dy2)

        return abs(dotProduct) < 0.1 && magnitude1 > 0 && magnitude2 > 0
    }
}

// MARK: - Отрисовка объектов сцены
extension VectorsScene {
    private func drawVector(_ vector: Vector, color: UIColor, lineWidth: CGFloat = 4) {
        let path = CGMutablePath()

        // Рисуем основную линию вектора
        path.move(to: vector.startPoint)
        path.addLine(to: vector.endPoint)

        // Динамическая длина треугольника зависит от толщины линии
        let arrowLength = 10.0 // Базовая длина увеличивается с толщиной линии
        let angle: CGFloat = .pi / 6.0 // Угол отклонения треугольника
        let vectorAngle = atan2(vector.endPoint.y - vector.startPoint.y, vector.endPoint.x - vector.startPoint.x) // Угол основного вектора

        // Вычисляем точки для треугольника-наконечника
        let arrowPoint1 = CGPoint(
            x: vector.endPoint.x - arrowLength * cos(vectorAngle - angle),
            y: vector.endPoint.y - arrowLength * sin(vectorAngle - angle)
        )
        let arrowPoint2 = CGPoint(
            x: vector.endPoint.x - arrowLength * cos(vectorAngle + angle),
            y: vector.endPoint.y - arrowLength * sin(vectorAngle + angle)
        )

        // Добавляем треугольник-наконечник
        path.move(to: arrowPoint1)
        path.addLine(to: arrowPoint2)
        path.addLine(to: vector.endPoint)
        path.closeSubpath()

        // Создаём единый SKShapeNode для линии и треугольника
        let vectorNode = SKShapeNode(path: path)
        vectorNode.strokeColor = color // Цвет линии
        vectorNode.lineWidth = lineWidth // Толщина для основной линии
        vectorNode.fillColor = vectorNode.strokeColor // Треугольник закрашен цветом линии
        vectorNode.name = "vector-\(vector.id)"

        // Добавляем на сцену
        addChild(vectorNode)
    }
    
    // Перерисовка вектора
    private func redrawVector(_ vector: Vector) {
        for child in children {
            if child.name == "vector-\(vector.id)" {
                child.removeFromParent()
            }
        }
        
        let color = vectorColors[vector.id] ?? .blue
        drawVector(vector, color: color)
    }
    
    // Удаление всех векторов со сцены
    private func removeAllVectors() {
        for child in children {
            // Проверяем, является ли имя узла связанным с вектором
            if child.name?.starts(with: "vector-") == true {
                child.removeFromParent()
            }
        }
    }
    
    // Отрисовка сетки
    private func addGrid(spacing: CGFloat, color: UIColor = .lightGray) {
        let path = CGMutablePath()
        
        // Вертикальные линии
        for x in stride(from: 0, through: size.width, by: spacing) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }
        
        // Горизонтальные линии
        for y in stride(from: 0, through: size.height, by: spacing) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }
        
        let gridNode = SKShapeNode(path: path)
        gridNode.strokeColor = color
        gridNode.lineWidth = 1
        
        addChild(gridNode)
    }
    
    // Отрисовка надписей на сетке
    private func addAxisLabels(spacing: CGFloat, color: UIColor = .lightGray) {
        // Метки для оси X (горизонтальной)
        for x in stride(from: 0, through: size.width, by: spacing) {
            let label = SKLabelNode(text: "\(Int(x))")
            label.fontSize = 16
            label.fontColor = color
            label.fontName = "Helvetica-Bold" // Устанавливаем жирный шрифт
            label.position = CGPoint(x: x, y: -15)
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            addChild(label)
        }
        
        // Метки для оси Y (вертикальной)
        for y in stride(from: 0, through: size.height, by: spacing) {
            let label = SKLabelNode(text: "\(Int(y))")
            label.fontSize = 16
            label.fontColor = color
            label.fontName = "Helvetica-Bold" // Устанавливаем жирный шрифт
            label.position = CGPoint(x: -20, y: y)
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            addChild(label)
        }
    }
    
    // Прорисовка квадрата в углу
    private func drawRightAngleIndicator(at point: CGPoint, vector1: Vector, vector2: Vector) {
        let squareSize: CGFloat = 20.0 // Размер квадратика

        // Нормализуем имя: гарантируем предсказуемый порядок идентификаторов
        let sortedIDs = [vector1.id, vector2.id].sorted()
        let indicatorName = "rightAngleIndicator-\(sortedIDs[0])-\(sortedIDs[1])"

        // Проверяем, есть ли уже индикатор для этой пары векторов, если есть, удаляем
        for child in children {
            if child.name == indicatorName {
                child.removeFromParent()
            }
        }

        // Проверяем, какие точки соединяются
        let vector1StartConnected = vector1.startPoint == point
        let vector2StartConnected = vector2.startPoint == point

        // Смещение для первого вектора
        let dx1 = vector1StartConnected
            ? vector1.endPoint.x - vector1.startPoint.x
            : vector1.startPoint.x - vector1.endPoint.x
        let dy1 = vector1StartConnected
            ? vector1.endPoint.y - vector1.startPoint.y
            : vector1.startPoint.y - vector1.endPoint.y

        // Смещение для второго вектора
        let dx2 = vector2StartConnected
            ? vector2.endPoint.x - vector2.startPoint.x
            : vector2.startPoint.x - vector2.endPoint.x
        let dy2 = vector2StartConnected
            ? vector2.endPoint.y - vector2.startPoint.y
            : vector2.startPoint.y - vector2.endPoint.y

        // Нормализуем направления
        let length1 = hypot(dx1, dy1)
        let normalizedDx1 = dx1 / length1
        let normalizedDy1 = dy1 / length1

        let length2 = hypot(dx2, dy2)
        let normalizedDx2 = dx2 / length2
        let normalizedDy2 = dy2 / length2

        // Углы квадрата с коррекцией знаков
        let corner1 = CGPoint(x: point.x, y: point.y) // Центр пересечения
        let corner2 = CGPoint(x: point.x + normalizedDx1 * squareSize, y: point.y + normalizedDy1 * squareSize)
        let corner3 = CGPoint(x: corner2.x + normalizedDx2 * squareSize, y: corner2.y + normalizedDy2 * squareSize)
        let corner4 = CGPoint(x: point.x + normalizedDx2 * squareSize, y: point.y + normalizedDy2 * squareSize)

        // Построение пути квадрата
        let path = CGMutablePath()
        path.move(to: corner1)
        path.addLine(to: corner2)
        path.addLine(to: corner3)
        path.addLine(to: corner4)
        path.closeSubpath()

        // Создание и добавление графического узла
        let squareNode = SKShapeNode(path: path)
        squareNode.fillColor = .clear
        squareNode.strokeColor = .red // Видимый цвет для проверки
        squareNode.lineWidth = 2
        squareNode.zPosition = 1
        squareNode.name = indicatorName // Привязываем имя индикатору

        addChild(squareNode)
    }
    
    // Удаление квадратика-индикатора
    private func removeRightAngleIndicator(for vector1: Vector, with vector2: Vector) {
        // Нормализуем имя: гарантируем предсказуемый порядок идентификаторов
        let sortedIDs = [vector1.id, vector2.id].sorted()
        let indicatorName = "rightAngleIndicator-\(sortedIDs[0])-\(sortedIDs[1])"
        
        for child in children {
            if child.name == indicatorName {
                child.removeFromParent()
            }
        }
    }
    
    // Проверка и удаление индикаторов
    private func validateAndRemoveIndicators(for vector: Vector) {
        for otherVector in vectors where otherVector !== vector {
            guard let commonPoint = findCommonPoint(between: vector, and: otherVector) else {
                // Если векторы больше не соединены, удаляем индикатор
                removeRightAngleIndicator(for: vector, with: otherVector)
                continue
            }
            // Если угол больше не прямой, удаляем индикатор
            if !isRightAngle(vector1: vector, vector2: otherVector, at: commonPoint) {
                removeRightAngleIndicator(for: vector, with: otherVector)
            }
        }
    }
    
    // Перерисовка всех квадратиков-индикаторов
    private func drawAllRightAngleIndicators() {
        // Удаляем все предыдущие индикаторы перед отрисовкой новых
        for child in children where child.name?.starts(with: "rightAngleIndicator") == true {
            child.removeFromParent()
        }
        
        for (i, vector1) in vectors.enumerated() {
            for vector2 in vectors[i + 1..<vectors.count] { // Итерируем только по последующим элементам
                guard let commonPoint = findCommonPoint(between: vector1, and: vector2),
                      isRightAngle(vector1: vector1, vector2: vector2, at: commonPoint) else {
                    continue
                }
                
                // Рисуем индикатор для прямого угла
                drawRightAngleIndicator(at: commonPoint, vector1: vector1, vector2: vector2)
            }
        }
    }
}

// MARK: - Камера
extension VectorsScene {
    // Настройка камеры
    private func setupCamera() {
        // Создаём узел камеры
        cameraNode = SKCameraNode()
        self.camera = cameraNode
        addChild(cameraNode) // Добавляем камеру в сцену
        
        // Устанавливаем начальную позицию камеры на центр экрана
        let cameraViewWidth = view?.bounds.width ?? 0
        let cameraViewHeight = view?.bounds.height ?? 0
        cameraNode.position = CGPoint(x: cameraViewWidth / 2, y: cameraViewHeight / 2)

        // Настраиваем распознавание жеста пинча для масштабирования камеры
        setupPinchGesture()
    }

    // Перемещение камеры с учётом масштаба и размера сцены
    private func moveCamera(by translation: CGPoint) {
        guard let camera = cameraNode else { return } // Проверяем, что камера существует

        // Вычисляем новое положение камеры с учётом текущего положения и смещения
        var newPosition = CGPoint(
            x: camera.position.x + translation.x,
            y: camera.position.y + translation.y
        )

        // Получаем размеры области обзора камеры с учётом масштаба
        let cameraViewWidth = (view?.bounds.width ?? 0) * camera.xScale
        let cameraViewHeight = (view?.bounds.height ?? 0) * camera.yScale

        // Проверяем, превышает ли область камеры размеры сцены
        if cameraViewWidth >= size.width {
            // Если ширина видимой области больше ширины сцены, разрешаем камере двигаться свободно по горизонтали
            newPosition.x = size.width / 2
        } else {
            // Ограничиваем положение камеры по оси X
            let minX = cameraViewWidth / 2
            let maxX = size.width - cameraViewWidth / 2
            newPosition.x = max(minX, min(maxX, newPosition.x))
        }

        if cameraViewHeight >= size.height {
            // Если высота видимой области больше высоты сцены, разрешаем камере двигаться свободно по вертикали
            newPosition.y = size.height / 2
        } else {
            // Ограничиваем положение камеры по оси Y
            let minY = cameraViewHeight / 2
            let maxY = size.height - cameraViewHeight / 2
            newPosition.y = max(minY, min(maxY, newPosition.y))
        }

        // Устанавливаем новое положение камеры
        camera.position = newPosition
    }

    // Настройка жеста для масштабирования (пинча)
    private func setupPinchGesture() {
        guard let view = self.view else { return } // Убедимся, что view доступен

        // Создаём распознаватель жестов для пинча
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        view.addGestureRecognizer(pinchGesture) // Добавляем распознаватель в view
    }

    // Обработка жеста пинча
    @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard let camera = cameraNode else { return } // Проверяем, что камера существует

        // Вычисляем новый масштаб на основе жеста
        let scale = gesture.scale
        let newScale = max(0.5, min(camera.xScale / scale, 3.0)) // Ограничиваем масштаб от 0.5 до 3.0

        // Устанавливаем новый масштаб камеры
        camera.setScale(newScale)

        // Сбрасываем значение scale жеста, чтобы дальнейшие изменения были корректными
        gesture.scale = 1.0
    }
}

extension UIColor {
    static func random(highContrastWithWhite: Bool = true) -> UIColor {
        var color: UIColor
        repeat {
            // Генерируем случайный цвет
            let red = CGFloat.random(in: 0...1)
            let green = CGFloat.random(in: 0...1)
            let blue = CGFloat.random(in: 0...1)
            color = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        } while highContrastWithWhite && !isHighContrastColor(color)

        return color
    }

    private static func isHighContrastColor(_ color: UIColor) -> Bool {
        // Получаем компоненты цвета (R, G, B)
        guard let components = color.cgColor.components, components.count >= 3 else {
            return false
        }
        let red = components[0]
        let green = components[1]
        let blue = components[2]

        // Вычисляем относительную яркость
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue

        // Проверяем контрастность: цвет считается высококонтрастным, если он достаточно тёмный
        return luminance < 0.8 // Чем меньше значение, тем лучше виден цвет на белом фоне
    }
}

extension CGPoint {
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
