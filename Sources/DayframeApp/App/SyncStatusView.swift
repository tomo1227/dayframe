import DayframeCore
import SwiftUI

struct SyncStatusView: View {
  let monitor: SyncMonitor

  var body: some View {
    Menu {
      Text(label)
      if case .synced(let date) = monitor.state { Text(date, format: .dateTime.hour().minute()) }
      if case .failed(let message) = monitor.state { Text(message) }
      Button("Check iCloud", systemImage: "arrow.clockwise", action: check)
    } label: {
      Label(label, systemImage: symbol)
    }
    .help(label)
  }

  private var label: String {
    switch monitor.state {
    case .localOnly: String(localized: "Local storage")
    case .checking: String(localized: "Checking iCloud")
    case .waiting: String(localized: "Waiting for iCloud")
    case .syncing: String(localized: "Syncing")
    case .synced: String(localized: "Synced with iCloud")
    case .unavailable: String(localized: "iCloud unavailable · saved locally")
    case .failed: String(localized: "Sync failed · saved locally")
    }
  }
  private var symbol: String {
    switch monitor.state {
    case .localOnly: "externaldrive"
    case .checking, .waiting: "icloud"
    case .syncing: "arrow.triangle.2.circlepath.icloud"
    case .synced: "checkmark.icloud"
    case .unavailable, .failed: "exclamationmark.icloud"
    }
  }
  private func check() { Task { await monitor.start() } }
}
