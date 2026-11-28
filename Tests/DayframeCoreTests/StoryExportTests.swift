import CoreText
import DayframeExport
import Foundation
import ImageIO
import Testing

@testable import DayframeCore
@testable import DayframeExport

struct StoryExportTests {
  @Test(arguments: [StoryFont.sans, .serif])
  func japaneseExportFontsProvideKanaAndKanji(font: StoryFont) {
    let face = CTFontCreateWithName(font.postScriptName as CFString, 17, nil)
    #expect(CTFontCopyPostScriptName(face) as String == font.postScriptName)
    let sample = Array("ひらがなカタカナ漢字".utf16)
    var glyphs = [CGGlyph](repeating: 0, count: sample.count)
    let hasGlyphs = CTFontGetGlyphsForCharacters(face, sample, &glyphs, sample.count)
    #expect(hasGlyphs)
    #expect(glyphs.allSatisfy { $0 != 0 })
  }

  @Test func codeFencesAndInlineBackticksAppearInExportOrder() {
    let markdown =
      "- Run `swift test`\n  Check `status`\n```swift\n  let n = 1\n```\nUse `n`\n- Done"
    let plan = MarkdownParser.parse(markdown, date: .now)
    let entries = StoryPaginator.pages(for: plan, options: StoryOptions(), markdown: markdown)
      .flatMap(\.entries)
    let titles = ["Run `swift test`", "```swift\n  let n = 1\n```", "Use `n`", "Done"]
    #expect(entries.map(\.title) == titles)
    #expect(entries.first?.description == "Check `status`")
    #expect(entries.filter(\.isCode).count == 2)
  }

  @Test func largerTextRepaginatesWithoutLosingTasksOrCode() {
    let code = "```\n" + (0..<40).map { "line \($0)" }.joined(separator: "\n") + "\n```"
    let markdown = (0..<25).map { "- Task \($0)" }.joined(separator: "\n") + "\n" + code
    let plan = MarkdownParser.parse(markdown, date: .now)
    var options = StoryOptions()
    let normal = StoryPaginator.pages(for: plan, options: options, markdown: markdown)
    options.textScale = StoryOptions.textScaleRange.upperBound
    let larger = StoryPaginator.pages(for: plan, options: options, markdown: markdown)
    #expect(larger.count > normal.count)
    #expect(larger.allSatisfy { $0.entries.reduce(0) { $0 + $1.height } <= 330 })
    #expect(larger.flatMap(\.entries).filter { !$0.isCode }.map(\.title) == plan.tasks.map(\.title))
    #expect(larger.flatMap(\.entries).filter(\.isCode).map(\.title).joined(separator: "\n") == code)
  }

  @Test func longPlansPaginateWithoutDroppingTasks() {
    let markdown =
      "## Work\n"
      + (0..<60).map { "- [ ] 09:00 Task \($0)\n  A thoughtful description" }.joined(
        separator: "\n")
    let plan = MarkdownParser.parse(markdown, date: .now)
    var options = StoryOptions()
    options.includedSections = Set(plan.sections.map(\.id))
    let pages = StoryPaginator.pages(for: plan, options: options)
    #expect(pages.count > 1)
    #expect(pages.flatMap(\.entries).count == 60)
    #expect(pages.allSatisfy { $0.entries.reduce(0) { $0 + $1.height } <= 330 })
  }

  @Test(arguments: StoryAspectRatio.allCases)
  func longEntriesFitEachAspectRatio(ratio: StoryAspectRatio) throws {
    let title = String(repeating: "Long title ", count: 80) + "end"
    let description = String(repeating: "Long description ", count: 100) + "end"
    let code = "```\n" + (0..<36).map { "line \($0)" }.joined(separator: "\n") + "\n```"
    let markdown = "## Work\n- \(title)\n  \(description)\n\(code)"
    let plan = MarkdownParser.parse(markdown, date: .now)
    let task = try #require(plan.tasks.first)
    var options = StoryOptions()
    options.aspectRatio = ratio
    options.textScale = StoryOptions.textScaleRange.upperBound
    options.includedSections = Set(plan.sections.map(\.id))
    let pages = StoryPaginator.pages(for: plan, options: options, markdown: markdown)
    let entries = pages.flatMap(\.entries)
    let taskEntries = entries.filter { !$0.isCode }

    #expect(pages.count > 1)
    #expect(pages.allSatisfy { $0.entries.reduce(0) { $0 + $1.height } <= ratio.rowsHeight })
    #expect(taskEntries.map(\.title).joined().replacingOccurrences(of: "\n", with: "") == task.title)
    #expect(
      taskEntries.map(\.description).joined().replacingOccurrences(of: "\n", with: "")
        == task.description)
    #expect(entries.filter(\.isCode).map(\.title).joined(separator: "\n") == code)
  }

  @MainActor
  @Test(arguments: StoryAspectRatio.allCases)
  func aspectRatiosProduceExactPNGDimensions(ratio: StoryAspectRatio) throws {
    let plan = MarkdownParser.parse("- Task", date: .now)
    var options = StoryOptions()
    options.aspectRatio = ratio
    let page = try #require(StoryPaginator.pages(for: plan, options: options).first)
    let data = try StoryRenderer.png(
      plan: plan, page: page, options: options, locale: Locale(identifier: "en"))
    let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
    let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
    switch ratio {
    case .portrait:
      #expect(image.width == 1080 && image.height == 1920)
    case .landscape:
      #expect(image.width == 1920 && image.height == 1080)
    case .landscapeWide:
      #expect(image.width == 1920 && image.height == 1200)
    case .post:
      #expect(image.width == 1080 && image.height == 1350)
    }
  }

  @MainActor
  @Test(arguments: [StoryOptions.dateScaleRange.lowerBound, 1, StoryOptions.dateScaleRange.upperBound])
  func dateHeadingStaysCloseToDivider(scale: Double) throws {
    let date = Date(timeIntervalSince1970: 1_789_992_000)
    let plan = MarkdownParser.parse("- Task", date: date)
    var options = StoryOptions()
    options.dateStyle = .iso
    options.dateScale = scale
    let page = try #require(StoryPaginator.pages(for: plan, options: options).first)
    let data = try StoryRenderer.png(
      plan: plan, page: page, options: options, locale: Locale(identifier: "en"))
    let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
    let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
    let context = try #require(
      CGContext(
        data: nil, width: image.width, height: image.height, bitsPerComponent: 8,
        bytesPerRow: image.width, space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGImageAlphaInfo.none.rawValue))
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    let pixels = try #require(context.data).assumingMemoryBound(to: UInt8.self)
    let dividerY = try #require((0..<image.height).first { y in
      (120..<960).allSatisfy { pixels[y * context.bytesPerRow + $0] < 128 }
    })
    let headingBottom = try #require((0..<dividerY).last { y in
      (120..<960).contains { pixels[y * context.bytesPerRow + $0] < 128 }
    })
    #expect(dividerY - headingBottom <= 65)
  }

  @MainActor @Test func templatesProduceFullResolutionPNG() throws {
    let plan = MarkdownParser.parse(
      "# 2026-11-26\n## Morning\n- [x] 07:00 Morning routine\n  Start your day\n## Work\n- [ ] 09:00 Review pull requests\n- [ ] 10:00 Team meeting\n## Evening\n- [ ] 18:00 Bouldering",
      date: .now)
    for template in StoryTemplate.allCases {
      var options = StoryOptions()
      options.apply(template)
      options.dateScale = StoryOptions.dateScaleRange.upperBound
      options.textScale = StoryOptions.textScaleRange.upperBound
      options.includedSections = Set(plan.sections.map(\.id))
      let page = try #require(StoryPaginator.pages(for: plan, options: options).first)
      let data = try StoryRenderer.png(
        plan: plan, page: page, options: options, locale: Locale(identifier: "en"))
      let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
      let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
      #expect(image.width == 1080)
      #expect(image.height == 1920)
      #expect(data.count > 20_000)
      try data.write(
        to: URL.temporaryDirectory.appending(path: "dayframe-\(template.rawValue).png"))
    }
  }
}
