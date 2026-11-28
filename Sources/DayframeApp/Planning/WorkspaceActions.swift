import DayframeCore
import SwiftUI

struct WorkspaceActions: View {
  @AppStorage("dayframeAppearance") private var appearance: DayframeAppearance = .system
  @AppStorage("newPlanTemplate") private var draftTemplate: PlanDraftTemplate = .blank
  let session: EditorSession
  let addSection: () -> Void
  let editSection: (PlanSection) -> Void
  let importMarkdown: () -> Void
  let exportMarkdown: () -> Void
  let showRecovery: () -> Void

  var body: some View {
    Menu("Appearance", systemImage: "circle.lefthalf.filled") {
      Picker("Appearance", selection: $appearance) {
        ForEach(DayframeAppearance.allCases) { value in
          Text(value.title).tag(value)
        }
      }
    }
    Button("New section", systemImage: "text.badge.plus", action: addSection)
    Menu("Edit section", systemImage: "pencil") {
      ForEach(session.plan.sections) { section in
        Button(section.title, action: { editSection(section) })
      }
    }
    Button("Import Markdown", systemImage: "square.and.arrow.down", action: importMarkdown)
    Button("Export Markdown", systemImage: "doc.text", action: exportMarkdown)
    Menu("Template for new plans", systemImage: "doc.on.doc") {
      Picker("Template for new plans", selection: $draftTemplate) {
        ForEach(PlanDraftTemplate.allCases) { template in
          Text(template.title).tag(template)
        }
      }
    }
    Button("Recovered drafts", systemImage: "clock.arrow.circlepath", action: showRecovery)
    Button("Save", systemImage: "square.and.arrow.down", action: session.save).keyboardShortcut("s")
  }
}
