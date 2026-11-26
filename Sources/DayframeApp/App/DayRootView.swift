import DayframeCore
import SwiftData
import SwiftUI

struct DayRootView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.calendar) private var calendar
  @Environment(\.scenePhase) private var scenePhase
  @Query(sort: \DayRecord.date, order: .reverse) private var records: [DayRecord]
  @State private var selectedDate = Date.now
  @State private var record: DayRecord?
  @State private var loadError: String?
  @State private var preferredColumn: NavigationSplitViewColumn = .detail
  let sync: SyncMonitor

  var body: some View {
    NavigationSplitView(preferredCompactColumn: $preferredColumn) {
      DaySidebar(selectedDate: $selectedDate, records: records)
    } detail: {
      if let record {
        DayWorkspace(record: record, context: context, sync: sync)
          .id(record.id)
      } else if let loadError {
        ContentUnavailableView(
          "Unable to load plan", systemImage: "exclamationmark.circle",
          description: Text(loadError))
      } else {
        ProgressView()
      }
    }
    .task(id: DayRecord.key(for: selectedDate, calendar: calendar)) { loadDay() }
    .task { await sync.start() }
    .onChange(of: records.count) { loadDay() }
    .onChange(of: record?.dayKey) {
      if let record { selectedDate = record.displayDate(calendar: calendar) }
    }
    .onChange(of: scenePhase) { if scenePhase == .active { Task { await sync.start() } } }
  }

  private func loadDay() {
    do {
      record = try DayRepository(context: context).day(for: selectedDate, calendar: calendar)
      loadError = nil
      preferredColumn = .detail
    } catch { loadError = error.localizedDescription }
  }
}
