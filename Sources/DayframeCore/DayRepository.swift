import Foundation
import SwiftData

@MainActor
public final class DayRepository {
  public let context: ModelContext
  private let recoveryDirectory: URL

  public init(context: ModelContext, recoveryDirectory: URL = RecoveryArchive.directory) {
    self.context = context
    self.recoveryDirectory = recoveryDirectory
  }

  public func day(for date: Date, calendar: Calendar = .current) throws -> DayRecord {
    let key = DayRecord.key(for: date, calendar: calendar)
    let matches = try records(for: key)
    if let existing = matches.first(where: \.hasPlanContent) ?? matches.first {
      try reconcile(matches, keeping: existing)
      return existing
    }
    return DayRecord(date: date, markdown: "# \(key)\n\n", calendar: calendar)
  }

  @discardableResult
  public func save(_ record: DayRecord, markdown: String, plan: DailyPlan) throws -> Bool {
    let key = DayRecord.key(for: plan.date)
    let isDraft = record.modelContext == nil
    if isDraft && !DayRecord.hasPlanContent(markdown: markdown, dayKey: key) { return false }
    if isDraft || key != record.dayKey {
      guard try !records(for: key).contains(where: { $0.id != record.id }) else {
        throw DayConflictError.existingDay(key)
      }
    }
    if key != record.dayKey {
      let replacement = DayRecord(date: plan.date)
      record.date = replacement.date
      record.dayKey = replacement.dayKey
    }
    try record.update(markdown: markdown, plan: plan)
    if isDraft { context.insert(record) }
    try context.save()
    return true
  }

  private func records(for key: String) throws -> [DayRecord] {
    try context.fetch(
      FetchDescriptor<DayRecord>(
        predicate: #Predicate { $0.dayKey == key },
        sortBy: [SortDescriptor(\.updatedAt, order: .reverse), SortDescriptor(\.id)]))
  }

  private func reconcile(_ matches: [DayRecord], keeping winner: DayRecord) throws {
    guard matches.count > 1 else { return }
    let duplicates = matches.filter { $0.id != winner.id }
    for duplicate in duplicates {
      if duplicate.markdown != winner.markdown {
        try RecoveryArchive.save(
          duplicate.markdown, dayKey: duplicate.dayKey, directory: recoveryDirectory)
      }
    }
    for duplicate in duplicates { context.delete(duplicate) }
    try context.save()
  }
}
