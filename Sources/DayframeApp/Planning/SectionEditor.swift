import DayframeCore
import SwiftUI

struct SectionEditor: View {
  @Environment(\.dismiss) private var dismiss
  @State private var title: String
  let section: PlanSection?
  let session: EditorSession

  init(section: PlanSection?, session: EditorSession) {
    self.section = section
    self.session = session
    _title = State(initialValue: section?.title ?? "")
  }

  var body: some View {
    NavigationStack {
      Form { TextField("Section name", text: $title).font(DayframeStyle.japaneseBody()) }
        .navigationTitle(section == nil ? Text("New section") : Text("Edit section"))
        .toolbar {
          ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: cancel) }
          ToolbarItem(placement: .confirmationAction) {
            Button("Save", action: save).disabled(
              title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          }
        }
    }
    .frame(idealWidth: 400, idealHeight: 220)
  }

  private func cancel() { dismiss() }
  private func save() {
    session.reparse()
    if let section {
      guard let current = session.plan.sections.first(where: { $0.id == section.id }) else {
        session.error = String(
          localized: "This item changed on another device. Close the editor and try again.")
        return
      }
      session.setMarkdown(
        MarkdownEditing.renamingSection(current, title: title, in: session.markdown))
    } else {
      session.setMarkdown(
        session.markdown + "\n## \(title.trimmingCharacters(in: .whitespacesAndNewlines))\n")
    }
    session.save()
    dismiss()
  }
}
