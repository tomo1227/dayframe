import DayframeCore
import SwiftUI

struct WorkspaceLayout: View {
  @Binding var mode: EditorMode
  let session: EditorSession
  let edit: (PlanTask) -> Void

  init(session: EditorSession, mode: Binding<EditorMode>, edit: @escaping (PlanTask) -> Void) {
    self.session = session
    _mode = mode
    self.edit = edit
  }

  var body: some View {
    #if os(macOS)
      ViewThatFits(in: .horizontal) {
        HSplitView {
          MarkdownEditor(session: session).frame(minWidth: 280, idealWidth: 420)
          PlanTimeline(session: session, edit: edit).frame(minWidth: 360)
        }
        CompactWorkspace(session: session, mode: $mode, edit: edit)
      }
    #else
      AdaptiveWorkspace(session: session, mode: $mode, edit: edit)
    #endif
  }
}
