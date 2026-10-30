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

    // Warm dusk-to-midnight circadian gradient
    let bgColors = [
        CGColor(srgbRed: 0.11, green: 0.08, blue: 0.22, alpha: 1.0),
        CGColor(srgbRed: 0.42, green: 0.14, blue: 0.24, alpha: 1.0),
        CGColor(srgbRed: 0.96, green: 0.44, blue: 0.11, alpha: 1.0)
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 0.48, 1.0]
    if let grad = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(
            grad,
            start: CGPoint(x: 512, y: 940),
            end: CGPoint(x: 512, y: 84),
            options: []
        )
    }

    // Radial amber glow around the sun
    let glowColors = [
        CGColor(srgbRed: 1.0, green: 0.85, blue: 0.45, alpha: 0.72),
        CGColor(srgbRed: 1.0, green: 0.52, blue: 0.12, alpha: 0.0)
    ] as CFArray
    if let radial = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(
            radial,
            startCenter: CGPoint(x: 512, y: 540),
            startRadius: 20,
            endCenter: CGPoint(x: 512, y: 540),
            endRadius: 340,
            options: []
        )
    }

    // Sun disc
    ctx.setFillColor(CGColor(srgbRed: 1.0, green: 0.95, blue: 0.82, alpha: 1.0))
    ctx.fillEllipse(in: CGRect(x: 512 - 148, y: 556 - 148, width: 296, height: 296))

    // Crescent eclipse overlay inside sun disc
    ctx.setFillColor(CGColor(srgbRed: 0.20, green: 0.10, blue: 0.26, alpha: 0.86))
    ctx.fillEllipse(in: CGRect(x: 556 - 116, y: 590 - 116, width: 232, height: 232))

    // Horizon wave bars (Circadian LUT waves)
    let waveY: [(CGFloat, CGFloat, CGFloat)] = [
        (360, 320, 1.0),
        (284, 240, 0.82),
        (212, 160, 0.62)
    ]
    for (y, halfW, alpha) in waveY {
        let barRect = CGRect(x: 512 - halfW, y: y, width: halfW * 2, height: 34)
        let barPath = CGPath(roundedRect: barRect, cornerWidth: 17, cornerHeight: 17, transform: nil)
        ctx.setFillColor(CGColor(srgbRed: 1.0, green: 0.92, blue: 0.76, alpha: alpha))
        ctx.addPath(barPath)
        ctx.fillPath()
    }

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
