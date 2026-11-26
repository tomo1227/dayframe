import DayframeCore
import DayframeExport
import SwiftUI

struct StoryPreview: View {
  @Environment(\.locale) private var locale
  let plan: DailyPlan
  let pages: [StoryPage]
  let options: StoryOptions
  @Binding var selectedPage: Int

  var body: some View {
    VStack(spacing: 16) {
      if pages.indices.contains(selectedPage) {
        StoryCanvas(plan: plan, page: pages[selectedPage], options: options, locale: locale)
          .scaleEffect(0.7, anchor: .topLeading)
          .frame(width: 252, height: 448, alignment: .topLeading)
          .border(.secondary.opacity(0.3))
          .accessibilityLabel("Story preview")
      } else {
        ProgressView().frame(width: 252, height: 448)
      }
      if pages.count > 1 {
        Picker("Page", selection: $selectedPage) {
          ForEach(pages) { page in Text("\(page.id + 1) / \(page.total)").tag(page.id) }
        }
      }
    }
  }
}
