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
  let sync: SyncMonitor
  private var savedMarkdown: String

  init(record: DayRecord, context: ModelContext, sync: SyncMonitor) {
    self.record = record
    repository = DayRepository(context: context)
    self.sync = sync
    markdown = record.markdown
    savedMarkdown = record.markdown
    plan = record.plan
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
      sync.markPending()
      self.error = nil
    } catch { self.error = error.localizedDescription }
  }

  func saveAfterPause() async {
    do { try await Task.sleep(for: .milliseconds(350)) } catch { return }
    save()
  }

  func receiveRemoteChange() {
    guard record.markdown != savedMarkdown else { return }
    if markdown != savedMarkdown {
      do {
        try RecoveryArchive.save(markdown, dayKey: record.dayKey)
        error = String(
          localized: "A simultaneous edit arrived. Your draft was saved in Dayframe/Recovered.")
      } catch {
        self.error = error.localizedDescription
        return
      }
    }
    savedMarkdown = record.markdown
    setMarkdown(record.markdown)
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
