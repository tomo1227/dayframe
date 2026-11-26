import SwiftUI

struct StartupView: View {
  let runtime: ApplicationRuntime

  var body: some View {
    Group {
      if let storage = runtime.storage, let sync = runtime.sync {
        DayRootView(sync: sync).modelContainer(storage.container)
      } else if let error = runtime.error {
        ContentUnavailableView {
          Label("Unable to open Dayframe", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
          Text(error)
        } actions: {
          Button("Retry", action: runtime.retry)
        }
      } else {
        ProgressView("Dayframe")
      }
    }
    .task { runtime.open() }
    .tint(DayframeStyle.accent)
  }
}
