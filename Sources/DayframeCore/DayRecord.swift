import Foundation
import SwiftData

@Model
public final class DayRecord {
  public var id: UUID = UUID()
  public var date: Date = Date.now
  public var dayKey: String = ""
  public var markdown: String = ""
  public var identityData: Data = Data()
  public var createdAt: Date = Date.now
  public var updatedAt: Date = Date.now

  public init(date: Date, markdown: String = "", calendar: Calendar = .current) {
    var local = Calendar(identifier: .gregorian)
    local.timeZone = calendar.timeZone
    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
    self.date = utc.date(from: local.dateComponents([.year, .month, .day], from: date)) ?? date
    self.dayKey = Self.key(for: date, calendar: calendar)
    self.markdown = markdown
  }

  public var plan: DailyPlan {
    let previous = try? JSONDecoder().decode(DailyPlan.self, from: identityData)
    return MarkdownParser.parse(markdown, date: displayDate(), previous: previous, dayId: id)
  }

  public func update(markdown: String, plan: DailyPlan) throws {
    let data = try JSONEncoder().encode(plan)
    self.markdown = markdown
    identityData = data
    updatedAt = .now
  }

  public static func key(for date: Date, calendar: Calendar = .current) -> String {
    var gregorian = Calendar(identifier: .gregorian)
    gregorian.timeZone = calendar.timeZone
    let parts = gregorian.dateComponents([.year, .month, .day], from: date)
    let twoDigits = IntegerFormatStyle<Int>.number.precision(.integerLength(2)).grouping(.never)
      .locale(Locale(identifier: "en_US_POSIX"))
    return
      "\(parts.year ?? 0)-\((parts.month ?? 0).formatted(twoDigits))-\((parts.day ?? 0).formatted(twoDigits))"
  }

  public func displayDate(calendar: Calendar = .current) -> Date {
    let parts = dayKey.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return date }
    var gregorian = Calendar(identifier: .gregorian)
    gregorian.timeZone = calendar.timeZone
    return gregorian.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
      ?? date
  }
}
