import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum IconGenerator {
  static func png(size: Int) throws -> Data {
    guard
      let context = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8,
        bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    else {
      throw CocoaError(.coderInvalidValue)
    }
    let scale = CGFloat(size) / 1024
    context.scaleBy(x: scale, y: scale)
    context.setFillColor(CGColor(red: 0.12, green: 0.46, blue: 0.37, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    context.setStrokeColor(CGColor(gray: 1, alpha: 1))
    context.setLineWidth(20)
    context.stroke(CGRect(x: 148, y: 148, width: 728, height: 728))
    let font = CTFontCreateWithName("Georgia" as CFString, 520, nil)
    let attributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key(kCTFontAttributeName as String): font,
      NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 1, alpha: 1),
    ]
    let line = CTLineCreateWithAttributedString(
      NSAttributedString(string: "D", attributes: attributes))
    let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    context.textPosition = CGPoint(
      x: (1024 - bounds.width) / 2 - bounds.minX, y: (1024 - bounds.height) / 2 - bounds.minY)
    CTLineDraw(line, context)
    guard let image = context.makeImage() else { throw CocoaError(.coderInvalidValue) }
    let data = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(
        data, UTType.png.identifier as CFString, 1, nil)
    else {
      throw CocoaError(.fileWriteUnknown)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
    return data as Data
  }
}

let root = URL(filePath: FileManager.default.currentDirectoryPath)
let assets = root.appending(path: "Resources/Assets.xcassets/AppIcon.appiconset")
let iconset = root.appending(path: ".build/Dayframe.iconset")
try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for size in [16, 32, 64, 128, 256, 512, 1024] {
  try IconGenerator.png(size: size).write(to: assets.appending(path: "icon-\(size).png"))
}
for size in [16, 32, 128, 256, 512] {
  for scale in [1, 2] {
    let filename = scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@2x.png"
    try IconGenerator.png(size: size * scale).write(to: iconset.appending(path: filename))
  }
}
