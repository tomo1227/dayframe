import DayframeCore
import SwiftUI

struct TaskEditor: View {
  @Environment(\.dismiss) private var dismiss
  @State private var draft: TaskDraft
  let session: EditorSession

  init(draft: TaskDraft, session: EditorSession) {
    _draft = State(initialValue: draft)
    self.session = session
  }

  var body: some View {
    NavigationStack {
      Form {
        TextField("Task", text: $draft.title, axis: .vertical).accessibilityIdentifier("task-title")
        TextField("Time (HH:mm)", text: $draft.time)
          .monospacedDigit()
        if !MarkdownEditing.validTime(draft.time) {
          Label("Enter a time from 00:00 to 23:59", systemImage: "exclamationmark.circle")
            .foregroundStyle(.red)
        }
        TextField("Notes", text: $draft.description, axis: .vertical).lineLimit(3...8)
        Picker("Section", selection: $draft.sectionId) {
          Text("Unsectioned").tag(UUID?.none)
          ForEach(session.plan.sections) { section in
            Text(section.title).tag(Optional(section.id))
          }
        }
        .disabled(draft.task != nil)
      }
      .navigationTitle(draft.task == nil ? Text("New task") : Text("Edit task"))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: cancel) }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save", action: save)
            .disabled(
              draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !MarkdownEditing.validTime(draft.time))
        }
      }
    }
    .frame(idealWidth: 440, idealHeight: 380)
  }

  private func cancel() { dismiss() }
  private func save() {
    session.reparse()
    if let original = draft.task {
      guard let task = session.plan.tasks.first(where: { $0.id == original.id }) else {
        session.error = String(
          localized: "This item changed on another device. Close the editor and try again.")
        return
      }
      session.setMarkdown(
        MarkdownEditing.replacingTask(
          task, title: draft.title, time: draft.time,
          description: draft.description, in: session.markdown))
    } else {
      let section = session.plan.sections.first { $0.id == draft.sectionId }
      guard draft.sectionId == nil || section != nil else {
        session.error = String(
          localized: "This item changed on another device. Close the editor and try again.")
        return
      }
      session.setMarkdown(
        MarkdownEditing.addingTask(
          title: draft.title, time: draft.time,
          description: draft.description, section: section, plan: session.plan, in: session.markdown
        ))
    }
    session.save()
    dismiss()
  }
}
