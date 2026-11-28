import SwiftUI

@main
struct DayframeApp: App {
  @AppStorage("dayframeAppearance") private var appearance: DayframeAppearance = .system
  @State private var runtime = ApplicationRuntime()

  var body: some Scene {
    WindowGroup {
      StartupView(runtime: runtime)
        .preferredColorScheme(appearance.colorScheme)
    }
    .defaultSize(width: 1120, height: 800)
  }
}
