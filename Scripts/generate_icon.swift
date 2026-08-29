import AppKit
import Foundation

let output = CommandLine.arguments.dropFirst().first ?? "."
let manager = FileManager.default
try manager.createDirectory(atPath: output, withIntermediateDirectories: true)

let files: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func render(size: Int, path: String) throws {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: .alphaFirst,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { throw NSError(domain: "ItoCanvasIcon", code: 1) }

    bitmap.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "ItoCanvasIcon", code: 2)
    }
    NSGraphicsContext.current = context

    let canvas = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    canvas.fill()

    let inset = CGFloat(size) * 0.055
    let body = canvas.insetBy(dx: inset, dy: inset)
    let radius = CGFloat(size) * 0.215
    let background = NSBezierPath(roundedRect: body, xRadius: radius, yRadius: radius)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.035, green: 0.075, blue: 0.17, alpha: 1),
        NSColor(calibratedRed: 0.035, green: 0.29, blue: 0.40, alpha: 1)
    ])!
    gradient.draw(in: background, angle: 62)

    let gridColor = NSColor.white.withAlphaComponent(0.10)
    gridColor.setStroke()
    let grid = NSBezierPath()
    grid.lineWidth = max(1, CGFloat(size) * 0.008)
    for fraction in [0.30, 0.50, 0.70] {
        let y = CGFloat(size) * fraction
        grid.move(to: NSPoint(x: CGFloat(size) * 0.16, y: y))
        grid.line(to: NSPoint(x: CGFloat(size) * 0.84, y: y))
    }
    grid.stroke()

    let chart = NSBezierPath()
    chart.lineWidth = max(1.5, CGFloat(size) * 0.045)
    chart.lineCapStyle = .round
    chart.lineJoinStyle = .round
    chart.move(to: NSPoint(x: CGFloat(size) * 0.16, y: CGFloat(size) * 0.31))
    chart.curve(
        to: NSPoint(x: CGFloat(size) * 0.84, y: CGFloat(size) * 0.69),
        controlPoint1: NSPoint(x: CGFloat(size) * 0.35, y: CGFloat(size) * 0.30),
        controlPoint2: NSPoint(x: CGFloat(size) * 0.58, y: CGFloat(size) * 0.73)
    )
    NSColor(calibratedRed: 0.35, green: 0.95, blue: 0.80, alpha: 1).setStroke()
    chart.stroke()

    let font = NSFont.systemFont(ofSize: CGFloat(size) * 0.46, weight: .bold)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph,
        .kern: -CGFloat(size) * 0.018
    ]
    let delta = "Δ"
    let textRect = NSRect(
        x: CGFloat(size) * 0.19,
        y: CGFloat(size) * 0.30,
        width: CGFloat(size) * 0.62,
        height: CGFloat(size) * 0.52
    )
    delta.draw(in: textRect, withAttributes: attributes)

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "ItoCanvasIcon", code: 3)
    }
    try data.write(to: URL(fileURLWithPath: path))
}

for (name, size) in files {
    try render(size: size, path: (output as NSString).appendingPathComponent(name))
}
