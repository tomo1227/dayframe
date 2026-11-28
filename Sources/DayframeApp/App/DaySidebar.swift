import DayframeCore
import SwiftUI

struct DaySidebar: View {
  @Environment(\.calendar) private var calendar
  let selectedDate: Date
  let records: [DayRecord]
  let selectDate: @MainActor @Sendable (Date) -> Void

  var body: some View {
    List {
      Section {
        #if os(iOS)
          DayCalendar(selectedDate: selectedDate, selectDate: selectDate)
        #else
          DatePicker(
            "Date", selection: Binding(get: { selectedDate }, set: selectDate),
            displayedComponents: .date
          )
          .datePickerStyle(.graphical)
        #endif
        Button("Today", systemImage: "calendar", action: today)
          .keyboardShortcut("t", modifiers: [.command, .shift])
      }
      Section("Your days") {
        ForEach(uniqueDays) { record in
          Button(action: { select(record) }) {
            HStack {
              Text(
                record.displayDate(calendar: calendar),
                format: .dateTime.month(.abbreviated).day().weekday(.abbreviated))
              Spacer()
              if calendar.isDate(record.displayDate(calendar: calendar), inSameDayAs: selectedDate)
              {
                Image(systemName: "circle.fill").font(.caption)
                  .foregroundStyle(.tint)
                  .accessibilityHidden(true)
              }
            }
          }
          .buttonStyle(.plain).frame(minHeight: 44)
          .accessibilityIdentifier("saved-day-\(record.dayKey)")
        }
      }
    }
    #if os(macOS)
      .navigationTitle("Dayframe")
    #endif
    .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 340)
  }

  private var uniqueDays: [DayRecord] {
    var seen: Set<String> = []
    return records.filter { $0.hasPlanContent && seen.insert($0.dayKey).inserted }
  }
  private func today() { selectDate(.now) }
  private func select(_ record: DayRecord) { selectDate(record.displayDate(calendar: calendar)) }
}
