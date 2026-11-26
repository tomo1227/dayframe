import DayframeCore
import SwiftUI

struct WorkspaceActions: View {
  let session: EditorSession
  let addSection: () -> Void
  let editSection: (PlanSection) -> Void
  let importMarkdown: () -> Void
  let exportMarkdown: () -> Void
  let showRecovery: () -> Void

  var body: some View {
    Button("New section", systemImage: "text.badge.plus", action: addSection)
    Menu("Edit section", systemImage: "pencil") {
      ForEach(session.plan.sections) { section in
        Button(section.title, action: { editSection(section) })
      }
    }
    Button("Import Markdown", systemImage: "square.and.arrow.down", action: importMarkdown)
    Button("Export Markdown", systemImage: "doc.text", action: exportMarkdown)
    Button("Recovered drafts", systemImage: "clock.arrow.circlepath", action: showRecovery)
    Button("Save", systemImage: "square.and.arrow.down", action: session.save).keyboardShortcut("s")
  }
}
