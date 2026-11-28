import DayframeCore
import SwiftUI

struct CompactWorkspace: View {
  let session: EditorSession
  @Binding var mode: EditorMode
  let edit: (PlanTask) -> Void

  var body: some View {
    content
      .safeAreaBar(edge: .bottom) {
        Picker("View", selection: $mode) {
          Text("Plan").tag(EditorMode.plan)
          Text("Markdown").tag(EditorMode.markdown)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, DayframeStyle.spacing)
        .padding(.vertical, 8)
      }
  }

  @ContentBuilder private var content: some View {
    if mode == .plan {
      PlanTimeline(session: session, edit: edit)
    } else {
      MarkdownEditor(session: session)
    }
  }
}
