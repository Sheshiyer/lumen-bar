import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Renders a crisp macOS squircle icon for LumenBar and writes both AppIcon-preview.png and AppIcon.icns directly via CGImageDestination.
func renderIcon(size: Int) -> CGImage {
    let scale = CGFloat(size) / 1024.0
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Could not create CGContext")
    }

    ctx.scaleBy(x: scale, y: scale)

    let rect = CGRect(x: 0, y: 0, width: 1024, height: 1024)
    let insetRect = rect.insetBy(dx: 76, dy: 76)
    let squirclePath = CGPath(roundedRect: insetRect, cornerWidth: 196, cornerHeight: 196, transform: nil)

    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    // Graphite night, warming to ember at the horizon.
    let bgColors = [
        CGColor(srgbRed: 0.07, green: 0.06, blue: 0.09, alpha: 1.0),
        CGColor(srgbRed: 0.16, green: 0.10, blue: 0.14, alpha: 1.0),
        CGColor(srgbRed: 0.55, green: 0.24, blue: 0.10, alpha: 1.0)
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 0.55, 1.0]
    if let grad = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(
            grad,
            start: CGPoint(x: 512, y: 960),
            end: CGPoint(x: 512, y: 60),
            options: []
        )
    }

    // Two monitors: the main one warm, the second cooler, so the mark reads as a desk.
    func monitor(_ rect: CGRect, warm: Bool) {
        let body = CGPath(roundedRect: rect, cornerWidth: 34, cornerHeight: 34, transform: nil)
        ctx.setFillColor(CGColor(srgbRed: 0.05, green: 0.04, blue: 0.06, alpha: 0.9))
        ctx.addPath(body)
        ctx.fillPath()

        let glass = rect.insetBy(dx: 16, dy: 16)
        let glassPath = CGPath(roundedRect: glass, cornerWidth: 18, cornerHeight: 18, transform: nil)
        let tone: [CGColor] = warm
            ? [CGColor(srgbRed: 1.0, green: 0.62, blue: 0.28, alpha: 1),
               CGColor(srgbRed: 1.0, green: 0.86, blue: 0.55, alpha: 1)]
            : [CGColor(srgbRed: 0.35, green: 0.62, blue: 0.85, alpha: 1),
               CGColor(srgbRed: 0.95, green: 0.9, blue: 0.78, alpha: 1)]
        ctx.saveGState()
        ctx.addPath(glassPath)
        ctx.clip()
        if let fill = CGGradient(colorsSpace: colorSpace, colors: tone as CFArray, locations: [0, 1]) {
            ctx.drawLinearGradient(fill, start: CGPoint(x: glass.minX, y: glass.midY), end: CGPoint(x: glass.maxX, y: glass.midY), options: [])
        }
        ctx.restoreGState()

        let stand = CGRect(x: rect.midX - 34, y: rect.minY - 26, width: 68, height: 14)
        ctx.setFillColor(CGColor(srgbRed: 1.0, green: 0.93, blue: 0.82, alpha: 0.85))
        ctx.addPath(CGPath(roundedRect: stand, cornerWidth: 7, cornerHeight: 7, transform: nil))
        ctx.fillPath()
    }

    monitor(CGRect(x: 250, y: 470, width: 430, height: 300), warm: true)
    monitor(CGRect(x: 560, y: 560, width: 250, height: 176), warm: false)

    ctx.restoreGState()

    // Subtle outer glass rim
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.setStrokeColor(CGColor(srgbRed: 1.0, green: 0.86, blue: 0.65, alpha: 0.48))
    ctx.setLineWidth(10)
    ctx.strokePath()
    ctx.restoreGState()

    guard let cgImage = ctx.makeImage() else {
        fatalError("Failed to make CGImage")
    }
    return cgImage
}

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let previewURL = URL(fileURLWithPath: "\(outDir)/AppIcon-preview.png")
let icnsURL = URL(fileURLWithPath: "\(outDir)/AppIcon.icns")

let img1024 = renderIcon(size: 1024)
let rep = NSBitmapImageRep(cgImage: img1024)
if let png = rep.representation(using: .png, properties: [:]) {
    try png.write(to: previewURL)
}

let sizes = [16, 32, 64, 128, 256, 512, 1024]
guard let dest = CGImageDestinationCreateWithURL(icnsURL as CFURL, "com.apple.icns" as CFString, sizes.count, nil) else {
    fatalError("Could not create ICNS destination")
}
for sz in sizes {
    let cg = renderIcon(size: sz)
    CGImageDestinationAddImage(dest, cg, nil)
}
guard CGImageDestinationFinalize(dest) else {
    fatalError("Failed to finalize ICNS")
}
print("Generated \(icnsURL.path) and \(previewURL.path)")
