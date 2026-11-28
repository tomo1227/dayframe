import Foundation
import Testing

@testable import DayframeCore

struct MarkdownEditingTests {
  @Test func checklistConvertsPlainTextAndBulletsWithoutChangingCheckedItemsOrCode() {
    let text = "## Work\nFirst\n* Second\n- [x] Finished\n\n```\n- Sample\n```\nThird"
    let expected =
      "## Work\n- [ ] First\n- [ ] Second\n- [x] Finished\n\n```\n- Sample\n```\n- [ ] Third"
    #expect(MarkdownEditing.checklist(text, following: "") == expected)
    #expect(MarkdownEditing.checklist("- Sample", following: "```swift\n") == "- Sample")
    #expect(MarkdownEditing.checklist("", following: "# 2026-11-27\n\n") == "- [ ] ")
  }

  @Test func identityLookupEditsTheCurrentSourceLine() throws {
    let original = MarkdownParser.parse("## Work\n- First\n- Second", date: .now)
    let changed = "# Today\n\n## Work\n- Inserted\n- First\n- Second"
    let current = MarkdownParser.parse(changed, date: .now, previous: original)
    let task = try #require(current.tasks.first { $0.id == original.tasks[0].id })
    let edited = MarkdownEditing.replacingTask(
      task, title: "Edited first", time: "", description: "", in: changed)
    #expect(edited.contains("- Inserted\n- [ ] Edited first\n- Second"))
  }

  let source =
    "# Today\n## Work\n- [ ] 09:00 First\n  Notes\n- [x] Second\n\n> Keep\n## Evening\n- Dinner\n"

  @Test func editDeleteAndReorderPreserveOtherContent() {
    let plan = MarkdownParser.parse(source, date: .now)
    let first = plan.tasks[0]
    let edited = MarkdownEditing.replacingTask(
      first, title: "Changed", time: "10:00",
      description: "New notes", in: source)
    #expect(edited.contains("- [ ] 10:00 Changed\n  New notes"))
    #expect(edited.contains("> Keep"))
    let deleted = MarkdownEditing.deletingTask(first, in: source)
    #expect(!deleted.contains("Notes"))
    #expect(deleted.contains("- [x] Second"))
    let moved = MarkdownEditing.movingTask(first, by: 1, plan: plan, in: source)
    #expect(moved.contains("- [x] Second\n- [ ] 09:00 First\n  Notes"))
    #expect(moved.contains("> Keep\n## Evening"))
  }

  @Test func addingToSectionAndValidatingTimes() {
    let plan = MarkdownParser.parse(source, date: .now)
    let added = MarkdownEditing.addingTask(
      title: "Third", time: "", description: "",
      section: plan.sections[0], plan: plan, in: source)
    let parsed = MarkdownParser.parse(added, date: .now, previous: plan)
    #expect(parsed.tasks.first(where: { $0.title == "Third" })?.sectionId == plan.sections[0].id)
    #expect(MarkdownEditing.validTime("23:59"))
    #expect(!MarkdownEditing.validTime("24:00"))
    #expect(!MarkdownEditing.validTime("9:00"))
  }

  @Test func taskNotesFollowTheirTaskWhenEditedMovedOrDeleted() {
    let source = "@note Standalone\n- First\n@note Bring a charger\n- Second\n@note Check in"
    let plan = MarkdownParser.parse(source, date: .now)
    #expect(plan.tasks.map(\.description) == ["Bring a charger", "Check in"])
    let first = plan.tasks[0]
    let edited = MarkdownEditing.replacingTask(
      first, title: "Updated", time: "", description: "Bring two", in: source)
    #expect(edited == "@note Standalone\n- [ ] Updated\n@note Bring two\n- Second\n@note Check in")
    let moved = MarkdownEditing.movingTask(first, by: 1, plan: plan, in: source)
    #expect(moved == "@note Standalone\n- Second\n@note Check in\n- First\n@note Bring a charger")
    let deleted = MarkdownEditing.deletingTask(first, in: source)
    #expect(deleted == "@note Standalone\n- Second\n@note Check in")
  }
}
