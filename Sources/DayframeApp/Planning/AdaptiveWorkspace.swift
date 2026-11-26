import DayframeCore
import SwiftUI

#if os(iOS)
  struct AdaptiveWorkspace: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    let session: EditorSession
    @Binding var mode: EditorMode
    let edit: (PlanTask) -> Void

    var body: some View {
      if sizeClass == .regular && !typeSize.isAccessibilitySize {
        ViewThatFits(in: .horizontal) {
          HStack(spacing: 0) {
            MarkdownEditor(session: session).frame(minWidth: 280)
            Divider()
            PlanTimeline(session: session, edit: edit).frame(minWidth: 360)
          }
          CompactWorkspace(session: session, mode: $mode, edit: edit)
        }
      } else {
        CompactWorkspace(session: session, mode: $mode, edit: edit)
      }
    }
  }
#endif
