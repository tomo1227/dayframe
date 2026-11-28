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
    let canvasSize = options.aspectRatio.canvasSize
    let scale = min(252 / canvasSize.width, 448 / canvasSize.height)
    let previewWidth = canvasSize.width * scale
    let previewHeight = canvasSize.height * scale
    VStack(spacing: 16) {
      if pages.indices.contains(selectedPage) {
        StoryCanvas(plan: plan, page: pages[selectedPage], options: options, locale: locale)
          .scaleEffect(scale, anchor: .topLeading)
          .frame(width: previewWidth, height: previewHeight, alignment: .topLeading)
          .border(.secondary.opacity(0.3))
          .accessibilityLabel("Story preview")
      } else {
        ProgressView().frame(width: previewWidth, height: previewHeight)
      }
      if pages.count > 1 {
        Picker("Page", selection: $selectedPage) {
          ForEach(pages) { page in Text("\(page.id + 1) / \(page.total)").tag(page.id) }
        }
      }
    }
  }
}
