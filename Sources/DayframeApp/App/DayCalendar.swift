#if os(iOS)
  import SwiftUI

  struct DayCalendar: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @State private var browsedDate: Date
    @State private var showingMonthPicker = false
    let selectedDate: Date
    let selectDate: @MainActor @Sendable (Date) -> Void

    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    init(selectedDate: Date, selectDate: @escaping @MainActor @Sendable (Date) -> Void) {
      self.selectedDate = selectedDate
      self.selectDate = selectDate
      _browsedDate = State(initialValue: selectedDate)
    }

    var body: some View {
      if let month = calendar.dateInterval(of: .month, for: browsedDate) {
        let leading =
          (calendar.component(.weekday, from: month.start) - calendar.firstWeekday + 7) % 7
        VStack(spacing: 4) {
          HStack {
            Button(action: toggleMonthPicker) {
              Label {
                Text(month.start, format: dateFormat.month(.wide).year())
                  .font(.headline)
              } icon: {
                Image(systemName: showingMonthPicker ? "chevron.up" : "chevron.down")
              }
              .labelStyle(.titleAndIcon)
            }
            .accessibilityIdentifier("calendar-month-picker")
            .frame(maxWidth: .infinity, alignment: .leading)
            Button("Previous month", systemImage: "chevron.backward", action: previousMonth)
            Button("Next month", systemImage: "chevron.forward", action: nextMonth)
          }
          .labelStyle(.iconOnly)
          .buttonStyle(.borderless)
          if showingMonthPicker {
            DatePicker("Date", selection: $browsedDate, displayedComponents: .date)
              .datePickerStyle(.wheel)
              .labelsHidden()
          } else {
            LazyVGrid(columns: Self.columns, spacing: 0) {
              ForEach(0..<7) { index in
                if let date = calendar.date(byAdding: .day, value: index - leading, to: month.start)
                {
                  Text(date, format: dateFormat.weekday(.narrow))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                }
              }
              ForEach(0..<leading, id: \.self) { _ in
                Color.clear.accessibilityHidden(true)
              }
              ForEach(days(in: month), id: \.self) { date in
                CalendarDayButton(date: date, selectedDate: selectedDate, selectDate: selectDate)
              }
            }
          }
        }
        .onChange(of: selectedDate) {
          browsedDate = selectedDate
          showingMonthPicker = false
        }
      }
    }

    private var dateFormat: Date.FormatStyle {
      .init(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
    }

    private func days(in month: DateInterval) -> [Date] {
      guard let range = calendar.range(of: .day, in: .month, for: month.start) else { return [] }
      return (0..<range.count).compactMap { offset in
        calendar.date(byAdding: .day, value: offset, to: month.start)
      }.filter { $0 < month.end }
    }

    private func previousMonth() { moveMonth(by: -1) }
    private func nextMonth() { moveMonth(by: 1) }
    private func toggleMonthPicker() { showingMonthPicker.toggle() }

    private func moveMonth(by offset: Int) {
      if let month = calendar.dateInterval(of: .month, for: browsedDate),
        let destination = calendar.date(byAdding: .month, value: offset, to: month.start)
      {
        browsedDate = destination
      }
    }
  }
#endif
