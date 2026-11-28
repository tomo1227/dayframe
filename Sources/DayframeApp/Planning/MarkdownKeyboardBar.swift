import DayframeCore
import SwiftUI

#if os(iOS)
  struct MarkdownKeyboardBar: ToolbarContent {
    let insert: (String) -> Void
    let insertToday: () -> Void
    let insertPlanDate: () -> Void
    let makeChecklist: () -> Void

    var body: some ToolbarContent {
      ToolbarItemGroup(placement: .keyboard) {
        ForEach(MarkdownKeyboardKey.primary, id: \.self) { key in
          Button {
            insert(key.insertion)
          } label: {
            Text(verbatim: key.symbol)
              .font(.body.monospaced())
          }
          .accessibilityLabel(Text(key.title))
          .accessibilityIdentifier(key.rawValue)
        }

        Button("Make checklist", systemImage: "checklist", action: makeChecklist)
          .labelStyle(.iconOnly)
          .accessibilityIdentifier("markdown-make-checklist")

        Menu {
          Button("Insert today's date", systemImage: "calendar", action: insertToday)
            .accessibilityIdentifier("markdown-insert-today")
          Button(
            "Insert plan date", systemImage: "calendar.badge.checkmark", action: insertPlanDate
          )
          .accessibilityIdentifier("markdown-insert-plan-date")
          Button("Insert task checkbox", systemImage: "square") { insert("- [ ] ") }
            .accessibilityIdentifier("markdown-insert-task")
          Button("Insert task note", systemImage: "note.text") {
            insert(MarkdownEditing.taskNotePrefix)
          }
          .accessibilityIdentifier("markdown-insert-note")
          Menu("More Markdown symbols", systemImage: "textformat") {
            ForEach(MarkdownKeyboardKey.additional, id: \.self) { key in
              Button(key.title) { insert(key.insertion) }
                .accessibilityIdentifier(key.rawValue)
            }
          }
        } label: {
          Label("Markdown shortcuts", systemImage: "ellipsis")
            .labelStyle(.iconOnly)
        }
        .accessibilityIdentifier("markdown-shortcuts")
      }
    }
  }
#endif
