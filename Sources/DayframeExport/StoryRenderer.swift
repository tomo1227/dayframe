import DayframeCore
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

@MainActor
public enum StoryRenderer {
  public static func png(plan: DailyPlan, page: StoryPage, options: StoryOptions, locale: Locale)
    throws -> Data
  {
    let renderer = ImageRenderer(
      content: StoryCanvas(plan: plan, page: page, options: options, locale: locale))
    renderer.scale = 3
    renderer.isOpaque = true
    guard let image = renderer.cgImage else { throw CocoaError(.coderInvalidValue) }
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

  public static func export(
    plan: DailyPlan, pages: [StoryPage], options: StoryOptions, locale: Locale
  ) throws -> [URL] {
    let directory = URL.temporaryDirectory.appending(
      path: "Dayframe-\(UUID())", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    do {
      return try pages.map { page in
        let url = directory.appending(path: "Dayframe-\(page.id + 1).png")
        try png(plan: plan, page: page, options: options, locale: locale).write(
          to: url, options: .atomic)
        return url
      }
    } catch {
      try? FileManager.default.removeItem(at: directory)
      throw error
    }
  }
}
