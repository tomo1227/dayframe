import DayframeCore
import SwiftUI

struct DaySidebar: View {
  @Environment(\.calendar) private var calendar
  @Binding var selectedDate: Date
  let records: [DayRecord]

  var body: some View {
    List {
      Section {
        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
          .datePickerStyle(.graphical)
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
                Image(systemName: "circle.fill").font(.caption).foregroundStyle(
                  DayframeStyle.accent
                )
                .accessibilityHidden(true)
              }
            }
          }
          .buttonStyle(.plain).frame(minHeight: 44)
        }
      }
    }
    .navigationTitle("Dayframe")
    .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 340)
  }

  private var uniqueDays: [DayRecord] {
    var seen: Set<String> = []
    return records.filter { $0.hasPlanContent && seen.insert($0.dayKey).inserted }
  }
  private func today() { selectedDate = .now }
  private func select(_ record: DayRecord) { selectedDate = record.displayDate(calendar: calendar) }
}
