import DayframeCore
import SwiftData
import SwiftUI

@MainActor @Observable
final class EditorSession {
  var markdown: String
  private(set) var plan: DailyPlan
  var error: String?
  let record: DayRecord
  let repository: DayRepository
  private var savedMarkdown: String
  private var lastRecordMarkdown: String

  init(record: DayRecord, context: ModelContext) {
    self.record = record
    repository = DayRepository(context: context)
    let editingMarkdown = record.markdownForEditing
    markdown = editingMarkdown
    savedMarkdown = editingMarkdown
    lastRecordMarkdown = record.markdown
    plan = record.plan
    if editingMarkdown != record.markdown { reparse() }
  }

  func reparse() {
    plan = MarkdownParser.parse(
      markdown, date: record.displayDate(), previous: plan, dayId: record.id)
  }

  func setMarkdown(_ value: String) {
    markdown = value
    reparse()
  }

  func save() {
    guard markdown != savedMarkdown else { return }
    reparse()
    do {
      try repository.save(record, markdown: markdown, plan: plan)
      savedMarkdown = markdown
      lastRecordMarkdown = record.markdown
      self.error = nil
    } catch { self.error = error.localizedDescription }
  }

  func saveAfterPause() async {
    do { try await Task.sleep(for: .milliseconds(350)) } catch { return }
    save()
  }

  func receiveRecordChange() {
    guard record.markdown != lastRecordMarkdown else { return }
    if markdown != savedMarkdown {
      do {
        try RecoveryArchive.save(markdown, dayKey: record.dayKey)
        error = String(
          localized: "This plan was edited in another window. Your draft was saved in Dayframe/Recovered.")
      } catch {
        self.error = error.localizedDescription
        return
      }
    }
    lastRecordMarkdown = record.markdown
    savedMarkdown = record.markdownForEditing
    setMarkdown(savedMarkdown)
  }

  func toggle(_ task: PlanTask) {
    setMarkdown(MarkdownParser.settingCompletion(!task.isCompleted, task: task, in: markdown))
    save()
  }

  func delete(_ task: PlanTask) {
    setMarkdown(MarkdownEditing.deletingTask(task, in: markdown))
    save()
  }
  func move(_ task: PlanTask, by offset: Int) {
    setMarkdown(MarkdownEditing.movingTask(task, by: offset, plan: plan, in: markdown))
    save()
  }
}
