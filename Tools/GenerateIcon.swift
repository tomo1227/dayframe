import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum IconGenerator {
  static func png(size: Int, sourceURL: URL) throws -> Data {
    guard
      let context = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8,
        bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    else {
      throw CocoaError(.coderInvalidValue)
    }
    guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(
        source, 0,
        [kCGImageSourceShouldCache: false] as CFDictionary)
    else {
      throw CocoaError(.fileReadUnknown)
    }
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size)))
    guard let rendered = context.makeImage() else { throw CocoaError(.coderInvalidValue) }
    let data = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(
        data, UTType.png.identifier as CFString, 1, nil)
    else {
      throw CocoaError(.fileWriteUnknown)
    }
    CGImageDestinationAddImage(destination, rendered, nil)
    guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
    return data as Data
  }
}

let root = URL(filePath: FileManager.default.currentDirectoryPath)
let assets = root.appending(path: "Resources/Assets.xcassets/AppIcon.appiconset")
let iconset = root.appending(path: ".build/Dayframe.iconset")
let source = root.appending(path: "Tools/source-icon.png")
guard
  let properties = CGImageSourceCreateWithURL(source as CFURL, nil).map({
    CGImageSourceCopyPropertiesAtIndex($0, 0, nil) as? [CFString: Any]
  }),
  let pixelWidth = properties?[kCGImagePropertyPixelWidth] as? Int,
  let pixelHeight = properties?[kCGImagePropertyPixelHeight] as? Int,
  pixelWidth > 0, pixelWidth == pixelHeight
else {
  FileHandle.standardError.write("icon.png must be a readable square image\n".data(using: .utf8)!)
  exit(1)
}
try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for size in [16, 32, 64, 128, 256, 512, 1024] {
  try IconGenerator.png(size: size, sourceURL: source)
    .write(to: assets.appending(path: "icon-\(size).png"))
}
for size in [16, 32, 128, 256, 512] {
  for scale in [1, 2] {
    let filename = scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@2x.png"
    try IconGenerator.png(size: size * scale, sourceURL: source)
      .write(to: iconset.appending(path: filename))
  }
}
