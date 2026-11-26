import DayframeExport
import Foundation
import ImageIO
import Testing

@testable import DayframeCore

struct StoryExportTests {
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

  @MainActor @Test func templatesProduceFullResolutionPNG() throws {
    let plan = MarkdownParser.parse(
      "# 2026-11-26\n## Morning\n- [x] 07:00 Morning routine\n  Start your day\n## Work\n- [ ] 09:00 Review pull requests\n- [ ] 10:00 Team meeting\n## Evening\n- [ ] 18:00 Bouldering",
      date: .now)
    for template in StoryTemplate.allCases {
      var options = StoryOptions()
      options.apply(template)
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
