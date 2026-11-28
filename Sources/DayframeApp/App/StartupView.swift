import SwiftUI

struct StartupView: View {
  @Environment(\.colorScheme) private var colorScheme
  let runtime: ApplicationRuntime

  var body: some View {
    Group {
      if let storage = runtime.storage {
        DayRootView().modelContainer(storage.container)
      } else if let error = runtime.error {
        ContentUnavailableView {
          Label("Unable to open Dayframe", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
          Text(error)
        } actions: {
          Button("Retry", action: runtime.retry)
            .buttonStyle(.glassProminent)
        }
      } else {
        ProgressView("Dayframe")
      }
    }
    .task { runtime.open() }
    .tint(DayframeStyle.accent(in: colorScheme))
  }
}
