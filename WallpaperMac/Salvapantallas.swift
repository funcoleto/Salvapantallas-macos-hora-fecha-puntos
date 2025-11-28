import ScreenSaver
import Cocoa
import Foundation

// MARK: - Constantes Globales
let MAX_CIRCLES: Int = 1500
// Reducción del factor de escala para reducir el tamaño total del bloque escalado.
let SCALE_FACTOR: CGFloat = 4.0

// MARK: - Utilidades de Color
private func randomColor() -> NSColor {
    return NSColor(
        hue: CGFloat.random(in: 0...1),
        saturation: CGFloat.random(in: 0.7...1.0),
        brightness: CGFloat.random(in: 0.8...1.0),
        alpha: 1.0
    )
}

// MARK: - Clases Auxiliares

class Circle {
    var position: NSPoint
    var radius: CGFloat
    var color: NSColor

    init(position: NSPoint, radius: CGFloat, color: NSColor) {
        self.position = position
        self.radius = radius
        self.color = color
    }

    func draw() {
        color.setFill()
        let circleRect = NSRect(x: position.x - radius, y: position.y - radius, width: radius * 2, height: radius * 2)
        NSBezierPath(ovalIn: circleRect).fill()
    }
}

class Square {
    var position: NSPoint
    var size: CGFloat
    var color: NSColor = .systemBlue
    var dx: CGFloat
    var dy: CGFloat
    var angle: CGFloat = 0.0      // <--- Nueva propiedad
    var rotationSpeed: CGFloat = 140.0 // <--- Velocidad de rotación

    init(position: NSPoint, size: CGFloat, speed: CGFloat) {
        self.position = position
        self.size = size
        self.dx = speed * (Bool.random() ? 1 : -1)
        self.dy = speed * (Bool.random() ? 1 : -1)
    }

    func draw() {
        NSGraphicsContext.saveGraphicsState()
        
        // Centra el origen en el centro del cuadrado, rota y compensa
        let transform = NSAffineTransform()
        transform.translateX(by: position.x, yBy: position.y)
        transform.rotate(byRadians: angle)
        transform.translateX(by: -size/2, yBy: -size/2)
        transform.concat()
        
        color.setFill()
        let squareRect = NSRect(x: 0, y: 0, width: size, height: size)
        squareRect.fill()

        NSGraphicsContext.restoreGraphicsState()
    }

    func update(bounds: NSRect) {
        position.x += dx
        position.y += dy
        
        // ** MODIFICACIÓN AQUÍ **
        // Incrementa el ángulo de rotación en cada actualización.
        angle += rotationSpeed * (CGFloat.pi / 180.0) // Convertimos grados a radianes
        // La rotación también debería invertir si la velocidad cambia
        // angle += (dx > 0) ? rotationSpeed : -rotationSpeed

        if position.x - size / 2 < bounds.minX || position.x + size / 2 > bounds.maxX {
            dx *= -1
            if position.x - size / 2 < bounds.minX { position.x = bounds.minX + size / 2 }
            if position.x + size / 2 > bounds.maxX { position.x = bounds.maxX - size / 2 }
        }

        if position.y - size / 2 < bounds.minY || position.y + size / 2 > bounds.maxY {
            dy *= -1
            if position.y - size / 2 < bounds.minY { position.y = bounds.minY + size / 2 }
            if position.y + size / 2 > bounds.maxY { position.y = bounds.maxY - size / 2 }
        }
    }
    
    func intersects(circle: Circle) -> Bool {
        let testX = max(position.x - size / 2, min(circle.position.x, position.x + size / 2))
        let testY = max(position.y - size / 2, min(circle.position.y, position.y + size / 2))
        
        let distX = circle.position.x - testX
        let distY = circle.position.y - testY
        let distance = sqrt((distX * distX) + (distY * distY))
        
        return distance <= circle.radius
    }
}

// MARK: - SalvapantallasView

class SalvapantallasView: ScreenSaverView {
    
    // MARK: Propiedades
    var square: Square!
    var circles: [Circle] = []
    var minuteCheckTimer: Timer?
    let squareSpeed: CGFloat = 17.0
    
    // MARK: Inicialización
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        self.animationTimeInterval = 1.0/30.0
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.animationTimeInterval = 1.0/30.0
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil && square == nil {
            setupGame()
            startAnimation()
        }
    }
    
    private func setupGame() {
        let dynamicSquareSize: CGFloat = self.bounds.width * 0.02
        let initialSquarePos = NSPoint(x: bounds.midX, y: bounds.minY + dynamicSquareSize)
        square = Square(position: initialSquarePos, size: dynamicSquareSize, speed: squareSpeed)
        
        spawnTimeCircles()
    }
    
    // MARK: - Ciclo de Animación
    
    override func startAnimation() {
        super.startAnimation()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.minuteCheckTimer?.invalidate()
            
            let now = Date()
            let calendar = Calendar.current
            let currentSecond = calendar.component(.second, from: now)
            let secondsUntilNext10 = 10 - (currentSecond % 10)
            
            let newMinuteTimer = Timer.scheduledTimer(
                timeInterval: 10.0,
                target: self,
                selector: #selector(self.handleTimeUpdate),
                userInfo: nil,
                repeats: true
            )
            newMinuteTimer.fireDate = now.addingTimeInterval(TimeInterval(secondsUntilNext10))
            
            self.minuteCheckTimer = newMinuteTimer
            RunLoop.main.add(newMinuteTimer, forMode: .common)
        }
    }
    
    @objc func handleTimeUpdate() {
        DispatchQueue.main.async {
            self.spawnTimeCircles()
        }
    }
    
    override func stopAnimation() {
        super.stopAnimation()
        DispatchQueue.main.async {
            self.minuteCheckTimer?.invalidate()
            self.minuteCheckTimer = nil
            self.circles.removeAll()
        }
    }
    
    override func animateOneFrame() {
        super.animateOneFrame()
        updateGame()
        self.setNeedsDisplay(self.bounds)
    }
    
    private func updateGame() {
        square.update(bounds: self.bounds)
        
        circles.removeAll { circle in
            if square.intersects(circle: circle) {
                square.color = randomColor()
                return true
            }
            return false
        }
    }
    
    // Genera el patrón de círculos a partir de la hora y fecha
    private func spawnTimeCircles() {
        circles.removeAll()
        
        if self.bounds.width < 50 || self.bounds.height < 50 { return }
        
        // --- CÁLCULO DINÁMICO DEL TAMAÑO DE FUENTE Y LÍMITES ---
        
        let dateSeparatorColor = NSColor(white: 0.7, alpha: 1.0)
        let timeSeparatorColor = NSColor(white: 0.7, alpha: 1.0)
        let timeNumbersColor = randomColor()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        let dateString = dateFormatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: Date())
        
        
        let heightScaleFactor: CGFloat = 2.1
        
        // 🚀 Ajuste CLAVE: Usamos el 80% de la dimensión mínima para garantizar margen
        let maxAllowedDimension = min(self.bounds.width, self.bounds.height) * 0.80
        
        // El tamaño de la fuente se calcula para que la altura del texto de dos líneas quepa en el límite escalado.
        var dynamicFontSize = maxAllowedDimension / (heightScaleFactor * SCALE_FACTOR)
        
        // Verificación de ancho para asegurar el límite:
        let estimatedMaxCharacters: CGFloat = 8.0
        let estimatedWidthPerCharacter: CGFloat = 0.6
        let maxFontSizeByWidth = maxAllowedDimension / (estimatedMaxCharacters * estimatedWidthPerCharacter * SCALE_FACTOR)
        
        dynamicFontSize = min(dynamicFontSize, maxFontSizeByWidth)
        
        // Límite inferior de la fuente
        dynamicFontSize = max(20.0, dynamicFontSize)
        
        // Definimos el radio del círculo en base al tamaño de fuente final
        let finalCircleRadius: CGFloat = dynamicFontSize * 0.08
        
        // --- FIN DE CÁLCULO DINÁMICO DEL TAMAÑO DE FUENTE Y LÍMITES ---
        
        // 3. Generar la cadena con el tamaño de fuente FINAL
        let commonAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: dynamicFontSize, weight: .bold)
        ]
        
        let attributedString = NSMutableAttributedString()
        
        // MARK: 1. CONSTRUCCIÓN DE LA LÍNEA DE LA FECHA
        let dateComponents = dateString.components(separatedBy: "/")
        
        for (index, component) in dateComponents.enumerated() {
            var dateNumberAttributes = commonAttributes
            dateNumberAttributes[.foregroundColor] = randomColor()
            attributedString.append(NSAttributedString(string: component, attributes: dateNumberAttributes))
            
            if index < dateComponents.count - 1 {
                var separatorAttributes = commonAttributes
                separatorAttributes[.foregroundColor] = dateSeparatorColor
                attributedString.append(NSAttributedString(string: "/", attributes: separatorAttributes))
            }
        }
        
        // Añadir Salto de Línea
        attributedString.append(NSAttributedString(string: "\n"))
        
        // MARK: 2. CONSTRUCCIÓN DE LA LÍNEA DE LA HORA (HH:mm)
        let timeComponents = timeString.components(separatedBy: ":")
        
        for (index, component) in timeComponents.enumerated() {
            var timeNumberAttributes = commonAttributes
            timeNumberAttributes[.foregroundColor] = timeNumbersColor
            attributedString.append(NSAttributedString(string: component, attributes: timeNumberAttributes))
            
            if index < timeComponents.count - 1 {
                var separatorAttributes = commonAttributes
                separatorAttributes[.foregroundColor] = timeSeparatorColor
                attributedString.append(NSAttributedString(string: ":", attributes: separatorAttributes))
            }
        }
        
        // 3. Aplicar Estilo de Párrafo Centrado
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attributedString.addAttribute(.paragraphStyle,
                                      value: paragraphStyle,
                                      range: NSRange(location: 0, length: attributedString.length))

        // Recalcular el tamaño del bitmap con el tamaño de fuente final
        var textSize = attributedString.size()
        let timeWidth = (timeString as NSString).size(withAttributes: commonAttributes).width
        let dateWidth = (dateString as NSString).size(withAttributes: commonAttributes).width
        textSize.width = max(timeWidth, dateWidth)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapSize = CGSize(width: textSize.width, height: textSize.height)
        
        // Configuración de Bitmap para RGBA
        guard let context = CGContext(data: nil,
                                      width: Int(bitmapSize.width),
                                      height: Int(bitmapSize.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return }
        
        // 5. Dibujar el texto en el contexto del mapa de bits
        NSGraphicsContext.saveGraphicsState()
        
        let bitmapContext = NSGraphicsContext(cgContext: context, flipped: true)
        NSGraphicsContext.current = bitmapContext
        
        context.setFillColor(CGColor.clear)
        context.fill(CGRect(origin: .zero, size: bitmapSize))
        
        // Dibujo que respeta formato de dos líneas y centrado
        let rectToDraw = NSRect(origin: .zero, size: textSize)
        attributedString.draw(in: rectToDraw)
        
        context.flush()
        
        NSGraphicsContext.restoreGraphicsState()
        
        // 6. Analizar el bitmap para crear los círculos (los "píxeles")
        guard let data = context.data else { return }
        let pixelData = data.assumingMemoryBound(to: UInt8.self)
        
        let bytesPerPixel = 4
        let totalHeight = textSize.height
        
        // Coordenadas iniciales para centrar todo el bloque en la vista
        let scaledTextWidth = textSize.width * SCALE_FACTOR
        let scaledTextHeight = totalHeight * SCALE_FACTOR
        
        // Centrado en la pantalla (vertical y horizontal)
        let startX = (self.bounds.width - scaledTextWidth) / 2
        let startY = (self.bounds.height - scaledTextHeight) / 2
        
        for y in 0..<Int(textSize.height) {
            for x in 0..<Int(textSize.width) {
                
                // Muestrear píxeles con el factor de escala
                if y % Int(SCALE_FACTOR) != 0 ||
                    x % Int(SCALE_FACTOR) != 0 {
                    continue
                }
                
                let offset = (y * context.bytesPerRow) + (x * bytesPerPixel)
                
                // LECTURA RGBA
                let red = pixelData[offset]
                let green = pixelData[offset + 1]
                let blue = pixelData[offset + 2]
                let alpha = pixelData[offset + 3]
                
                // Si hay opacidad (es parte de la letra)
                if alpha > 128 {
                    
                    let circlePosX = startX + CGFloat(x) * SCALE_FACTOR
                    let circlePosY = startY + CGFloat(y) * SCALE_FACTOR
                    
                    let r = CGFloat(red) / 255.0
                    let g = CGFloat(green) / 255.0
                    let b = CGFloat(blue) / 255.0
                    
                    let circleColor = NSColor(red: r, green: g, blue: b, alpha: 1.0)

                    let newCircle = Circle(position: NSPoint(x: circlePosX, y: circlePosY),
                                           radius: finalCircleRadius,
                                           color: circleColor)

                    if circles.count < MAX_CIRCLES {
                        circles.append(newCircle)
                    } else {
                        return
                    }
                }
            }
        }
    }
    
    // MARK: - Dibujo
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawGame()
    }
    
    private func drawGame() {
        // 1. Fondo
        let rect = self.bounds
        NSColor.black.setFill()
        rect.fill()
        
        // 2. Dibujar círculos
        for circle in circles {
            circle.draw()
        }
        
        // 3. Dibujar cuadrado
        square?.draw()
    }
}
