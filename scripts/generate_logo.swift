// Run from the repository root: swift scripts/generate_logo.swift
import AppKit

// Approved black and vivid green palette in sRGB.
let green = NSColor(srgbRed: 32/255, green: 230/255, blue: 160/255, alpha: 1).cgColor
let background = NSColor(srgbRed: 16/255, green: 19/255, blue: 18/255, alpha: 1).cgColor
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func render(_ path: String, size: Int, inset: CGFloat = 0, maskable: Bool = false) throws {
    let scale = 4
    let context = CGContext(data: nil, width: size * scale, height: size * scale,
        bitsPerComponent: 8, bytesPerRow: 0, space: space,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.scaleBy(x: CGFloat(size * scale) / 100, y: CGFloat(size * scale) / 100)
    context.translateBy(x: 0, y: 100)
    context.scaleBy(x: 1, y: -1)
    context.translateBy(x: inset, y: inset)
    context.scaleBy(x: (100 - inset * 2) / 100, y: (100 - inset * 2) / 100)
    context.setFillColor(background)
    context.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: 100, height: 100),
        cornerWidth: maskable ? 0 : 25, cornerHeight: maskable ? 0 : 25, transform: nil))
    context.fillPath()
    context.translateBy(x: 12.5, y: 12.5)
    context.scaleBy(x: 0.75, y: 0.75)
    func line(_ points: [CGPoint]) {
        context.setStrokeColor(green)
        context.setLineWidth(14)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.addLines(between: points)
        context.strokePath()
    }
    line([CGPoint(x: 27, y: 39), CGPoint(x: 27, y: 79)])
    line([CGPoint(x: 74, y: 23), CGPoint(x: 42, y: 51), CGPoint(x: 75, y: 79)])
    line([CGPoint(x: 29, y: 51), CGPoint(x: 42, y: 51)])
    context.setFillColor(green)
    context.fillEllipse(in: CGRect(x: 10, y: 12, width: 34, height: 34))
    context.setFillColor(background)
    context.fillEllipse(in: CGRect(x: 21, y: 23, width: 12, height: 12))

    let output = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
        bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    output.interpolationQuality = .high
    output.draw(context.makeImage()!, in: CGRect(x: 0, y: 0, width: size, height: size))
    let bitmap = NSBitmapImageRep(cgImage: output.makeImage()!)
    try bitmap.representation(using: .png, properties: [:])!
        .write(to: URL(fileURLWithPath: path))
}
try render("assets/images/keynest_mark.png", size: 1024)
try render("assets/images/app_icon_master.png", size: 1024)
for (density, scale) in [("mdpi", 1.0), ("hdpi", 1.5), ("xhdpi", 2.0), ("xxhdpi", 3.0), ("xxxhdpi", 4.0)] {
    let dir = "android/app/src/main/res/mipmap-\(density)"
    try render("\(dir)/ic_launcher.png", size: Int(48 * scale))
    try render("\(dir)/launch_logo.png", size: Int((61.44 * scale).rounded()))
    try render("\(dir)/launch_logo_v31.png", size: Int(288 * scale), inset: (1 - 61.44 / 288) * 50)
}
for size in [192, 512] {
    try render("web/icons/Icon-\(size).png", size: size)
    try render("web/icons/Icon-maskable-\(size).png", size: size, maskable: true)
}
try render("web/favicon.png", size: 32)
