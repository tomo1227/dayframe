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
        TextField("Task", text: $draft.title, axis: .vertical)
          .font(DayframeStyle.japaneseBody())
          .accessibilityIdentifier("task-title")
        Toggle("Set time", isOn: $draft.hasScheduledTime)
          .accessibilityIdentifier("task-set-time")
        if draft.hasScheduledTime {
          DatePicker("Time", selection: $draft.pickerTime, displayedComponents: .hourAndMinute)
            #if os(iOS)
              .datePickerStyle(.wheel)
            #else
              .datePickerStyle(.stepperField)
            #endif
            .environment(\.timeZone, .gmt)
        }
        TextField("Notes", text: $draft.description, axis: .vertical)
          .font(DayframeStyle.japaneseBody()).lineLimit(3...8)
        Picker("Section", selection: $draft.sectionId) {
          Text("Unsectioned").tag(UUID?.none)
          ForEach(session.plan.sections) { section in
            Text(section.title).tag(Optional(section.id))
          }
        }
        .disabled(draft.task != nil)
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: cancel) }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save", action: save)
            .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
