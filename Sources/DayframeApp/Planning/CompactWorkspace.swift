import DayframeCore
import SwiftUI

struct CompactWorkspace: View {
  let session: EditorSession
  @Binding var mode: EditorMode
  let edit: (PlanTask) -> Void

  var body: some View {
    VStack(spacing: 0) {
      Picker("View", selection: $mode) {
        Text("Plan").tag(EditorMode.plan)
        Text("Markdown").tag(EditorMode.markdown)
      }
      .pickerStyle(.segmented).padding(DayframeStyle.spacing)
      if mode == .plan {
        PlanTimeline(session: session, edit: edit)
      } else {
        MarkdownEditor(session: session)
      }
    }
  }
}
