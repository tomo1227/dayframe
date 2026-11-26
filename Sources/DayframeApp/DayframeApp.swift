import SwiftUI

@main
struct DayframeApp: App {
  @State private var runtime = ApplicationRuntime()

  var body: some Scene {
    WindowGroup { StartupView(runtime: runtime) }
      .defaultSize(width: 1120, height: 800)
  }
}
