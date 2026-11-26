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
    let descriptor = FetchDescriptor<DayRecord>(
      predicate: #Predicate { $0.dayKey == key },
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse), SortDescriptor(\.id)])
    let matches = try context.fetch(descriptor)
    if let existing = matches.first {
      try reconcile(matches, keeping: existing)
      return existing
    }
    let record = DayRecord(date: date, markdown: "# \(key)\n\n", calendar: calendar)
    context.insert(record)
    try context.save()
    return record
  }

  public func save(_ record: DayRecord, markdown: String, plan: DailyPlan) throws {
    let key = DayRecord.key(for: plan.date)
    if key != record.dayKey {
      let existing = try context.fetch(
        FetchDescriptor<DayRecord>(predicate: #Predicate { $0.dayKey == key }))
      guard !existing.contains(where: { $0.id != record.id }) else {
        throw DayConflictError.existingDay(key)
      }
      let replacement = DayRecord(date: plan.date)
      record.date = replacement.date
      record.dayKey = replacement.dayKey
    }
    try record.update(markdown: markdown, plan: plan)
    try context.save()
  }

  private func reconcile(_ matches: [DayRecord], keeping winner: DayRecord) throws {
    guard matches.count > 1 else { return }
    for duplicate in matches.dropFirst() {
      if duplicate.markdown != winner.markdown {
        try RecoveryArchive.save(
          duplicate.markdown, dayKey: duplicate.dayKey, directory: recoveryDirectory)
      }
    }
    for duplicate in matches.dropFirst() { context.delete(duplicate) }
    try context.save()
  }
}
