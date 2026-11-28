import DayframeCore
import SwiftData
import SwiftUI

struct DayRootView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.calendar) private var calendar
  @Environment(\.locale) private var locale
  @AppStorage("newPlanTemplate") private var draftTemplate: PlanDraftTemplate = .blank
  @Query(sort: \DayRecord.date, order: .reverse) private var records: [DayRecord]
  @State private var selectedDate = Date.now
  @State private var record: DayRecord?
  @State private var loadError: String?
  @State private var preferredColumn: NavigationSplitViewColumn = .detail

  var body: some View {
    NavigationSplitView(preferredCompactColumn: $preferredColumn) {
      DaySidebar(selectedDate: selectedDate, records: records, selectDate: selectDate)
    } detail: {
      if let record {
        DayWorkspace(record: record, context: context)
          .id(record.id)
      } else if let loadError {
        ContentUnavailableView(
          "Unable to load plan", systemImage: "exclamationmark.circle",
          description: Text(loadError))
      } else {
        ProgressView()
      }
    }
    .task { loadDay() }
    .onChange(of: selectedRecordIDs) { loadDay() }
    .onChange(of: record?.dayKey) {
      if let record, record.dayKey != selectedDayKey {
        selectedDate = record.displayDate(calendar: calendar)
      }
    }
  }

  private var selectedDayKey: String { DayRecord.key(for: selectedDate, calendar: calendar) }

  private var selectedRecordIDs: Set<UUID> {
    let key = selectedDayKey
    return Set(records.lazy.filter { $0.dayKey == key }.map(\.id))
  }

  private func selectDate(_ date: Date) {
    selectedDate = date
    loadDay()
    preferredColumn = .detail
  }

  private func loadDay() {
    let ids = selectedRecordIDs
    if let record, record.dayKey == selectedDayKey,
      ids == [record.id] || (ids.isEmpty && record.modelContext == nil)
    {
      return
    }
    do {
      record = try DayRepository(context: context).day(
        for: selectedDate, calendar: calendar, draftBody: draftTemplate.body(locale: locale))
      loadError = nil
    } catch {
      record = nil
      loadError = error.localizedDescription
    }
  }
}
