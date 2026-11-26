import DayframeCore
import SwiftUI

struct CalendarDayButton: View {
  @Environment(\.calendar) private var calendar
  @Environment(\.locale) private var locale
  let date: Date
  let selectedDate: Date
  let selectDate: @MainActor @Sendable (Date) -> Void

  var body: some View {
    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
    Button(action: openDay) {
      Text(date, format: dateFormat.day())
        .monospacedDigit()
        .fontWeight(isSelected || calendar.isDateInToday(date) ? .bold : .regular)
        .minimumScaleFactor(0.6)
        .lineLimit(1)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(isSelected ? Color.accentColor.opacity(0.22) : .clear, in: .circle)
        .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text(date, format: dateFormat.weekday(.wide).month(.wide).day().year()))
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityIdentifier("calendar-day-\(DayRecord.key(for: date, calendar: calendar))")
  }

  private var dateFormat: Date.FormatStyle {
    .init(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
  }

  private func openDay() { selectDate(date) }
}
