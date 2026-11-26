import Foundation
import SwiftData
import Testing

@testable import DayframeCore

@MainActor
struct StorageTests {
  @Test func duplicateDaysAreArchivedBeforeRemoval() throws {
    let schema = Schema([DayRecord.self])
    let container = try ModelContainer(
      for: schema,
      configurations: ModelConfiguration(
        schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none))
    let context = ModelContext(container)
    let older = DayRecord(date: .now, markdown: "# Today\n- Older task")
    let newer = DayRecord(date: .now, markdown: "# Today\n- Newer task")
    older.updatedAt = .distantPast
    context.insert(older)
    context.insert(newer)
    try context.save()
    let folder = URL.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let repository = DayRepository(context: context, recoveryDirectory: folder)
    #expect(try repository.day(for: .now).id == newer.id)
    #expect(try context.fetchCount(FetchDescriptor<DayRecord>()) == 1)
    let draft = try #require(RecoveryArchive.drafts(directory: folder).first)
    #expect(try String(contentsOf: draft.url, encoding: .utf8).contains("Older task"))
  }

  @Test func changingDateCannotOverwriteAnotherPlan() throws {
    let schema = Schema([DayRecord.self])
    let container = try ModelContainer(
      for: schema,
      configurations: ModelConfiguration(
        schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none))
    let repository = DayRepository(context: ModelContext(container))
    let today = try repository.day(for: .now)
    let tomorrowDate = try #require(Calendar.current.date(byAdding: .day, value: 1, to: .now))
    let tomorrow = try repository.day(for: tomorrowDate)
    let source = "# \(tomorrow.dayKey)\n- Changed"
    let original = today.markdown
    #expect(throws: DayConflictError.self) {
      try repository.save(today, markdown: source, plan: MarkdownParser.parse(source, date: .now))
    }
    #expect(today.markdown == original)
    #expect(tomorrow.markdown != source)
  }
  @Test func civilDateSurvivesTimeZoneChange() throws {
    var tokyo = Calendar(identifier: .gregorian)
    tokyo.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
    var losAngeles = Calendar(identifier: .gregorian)
    losAngeles.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
    let date = try #require(tokyo.date(from: DateComponents(year: 2026, month: 1, day: 3)))
    let record = DayRecord(date: date, calendar: tokyo)
    #expect(record.dayKey == "2026-01-03")
    #expect(
      DayRecord.key(for: record.displayDate(calendar: losAngeles), calendar: losAngeles)
        == "2026-01-03")
  }
  @Test func localStoreSurvivesReopeningWithoutCloud() throws {
    let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appending(path: "dayframe.store")
    let date = Date.now
    let source = "# Today\n## Work\n- [x] Ship Dayframe\n"
    var identity: UUID?
    do {
      let storage = try StorageBootstrap.open(at: url, cloudIdentifier: nil)
      #expect(!storage.cloudEnabled)
      let repository = DayRepository(context: ModelContext(storage.container))
      let record = try repository.day(for: date)
      let plan = MarkdownParser.parse(source, date: date, dayId: record.id)
      identity = plan.tasks.first?.id
      try repository.save(record, markdown: source, plan: plan)
      #expect(try repository.day(for: date).id == record.id)
    }
    let reopened = try StorageBootstrap.open(at: url, cloudIdentifier: nil)
    let record = try DayRepository(context: ModelContext(reopened.container)).day(for: date)
    #expect(record.markdown == source)
    #expect(record.plan.tasks.first?.id == identity)
    #expect(record.plan.tasks.first?.isCompleted == true)
  }

  @Test func unavailableCloudDoesNotClaimSync() async {
    let monitor = SyncMonitor(cloudIdentifier: nil)
    await monitor.start()
    monitor.markPending()
    #expect(monitor.state == .localOnly)
    let failed = SyncMonitor(cloudIdentifier: nil, startupFailure: "Cloud unavailable")
    await failed.start()
    #expect(failed.state == .failed("Cloud unavailable"))
  }
}
