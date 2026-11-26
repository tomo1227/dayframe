import Foundation
import Testing

@testable import DayframeCore

struct MarkdownParserTests {
  @Test func descriptionCannotCrossSectionOrParagraphBoundary() {
    let source =
      "- First\n  First notes\n\n  A separate paragraph\n## Work\n  Section notes\n- Second\n  Second notes"
    let plan = MarkdownParser.parse(source, date: .now)
    #expect(plan.tasks[0].description == "First notes")
    #expect(plan.tasks[1].description == "Second notes")
  }

  @Test func insertionDoesNotStealExistingIdentity() {
    let source = "## Work\n- First\n- Second"
    let plan = MarkdownParser.parse(source, date: .now)
    let inserted = MarkdownParser.parse(
      "## New\n- Added\n" + source.replacing("- First", with: "- New task\n- First"), date: .now,
      previous: plan)
    #expect(inserted.tasks.first(where: { $0.title == "First" })?.id == plan.tasks[0].id)
    #expect(inserted.tasks.first(where: { $0.title == "Second" })?.id == plan.tasks[1].id)
    #expect(inserted.sections.first(where: { $0.title == "Work" })?.id == plan.sections[0].id)
  }
  @Test func completionPreservesSource() {
    let source =
      "# 2026-11-26\n\n## Morning\n- [ ] 07:00 Read\n  A quiet start\n\n> Keep this note\n- Coffee\n"
    let plan = MarkdownParser.parse(source, date: .now)
    #expect(plan.tasks.count == 2)
    #expect(plan.tasks[0].scheduledTime == "07:00")
    #expect(plan.tasks[0].description == "A quiet start")
    let updated = MarkdownParser.settingCompletion(true, task: plan.tasks[0], in: source)
    #expect(updated == source.replacingOccurrences(of: "- [ ]", with: "- [x]"))
    let reparsed = MarkdownParser.parse(updated, date: .now, previous: plan)
    #expect(reparsed.tasks[0].id == plan.tasks[0].id)
    #expect(reparsed.tasks[0].isCompleted)
    #expect(reparsed.completedCount == 1)
  }

  @Test func tolerantParsingAndStableIdentity() {
    let source =
      "## Work\n- [x] 09:00 Review\n- [ ] 25:99 Invalid time\n```\n- not a task\n```\n- [ ]\n"
    let plan = MarkdownParser.parse(source, date: .now)
    #expect(plan.tasks.count == 3)
    #expect(plan.tasks[1].scheduledTime == nil)
    let updated = MarkdownParser.parse("\n" + source, date: .now, previous: plan)
    #expect(updated.tasks.map(\.id) == plan.tasks.map(\.id))
  }
}
