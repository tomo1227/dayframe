import DayframeCore
import SwiftUI

struct MarkdownEditor: View {
  @Bindable var session: EditorSession
  #if os(iOS)
    @Environment(\.calendar) private var calendar
    @FocusState private var isEditing: Bool
    @State private var selection: TextSelection?
  #endif

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Label("Markdown", systemImage: "text.alignleft")
        .font(.headline).padding(DayframeStyle.spacing)
      Divider()
      editor
        .font(DayframeStyle.japaneseBody()).padding(12)
        .autocorrectionDisabled()
        .accessibilityLabel("Daily plan Markdown")
        .accessibilityIdentifier("markdown-editor")
    }
  }

  @ContentBuilder
  private var editor: some View {
    #if os(iOS)
      TextEditor(text: $session.markdown, selection: $selection)
        .focused($isEditing)
        .toolbar {
          if isEditing {
            MarkdownKeyboardBar(
              insert: insert,
              insertToday: insertToday,
              insertPlanDate: insertPlanDate,
              makeChecklist: makeChecklist)
          }
        }
    #else
      TextEditor(text: $session.markdown)
    #endif
  }

  #if os(iOS)
    private func insertToday() {
      insert(DayRecord.key(for: .now, calendar: calendar))
    }

    private func insertPlanDate() {
      insert(session.record.dayKey)
    }

    private func insert(_ text: String) {
      let markdown = session.markdown
      replace(selectionRange(in: markdown), with: text, in: markdown)
    }

    private func selectionRange(in markdown: String) -> Range<String.Index> {
      if case .selection(let selectedRange) = selection?.indices {
        return selectedRange
      }
      return markdown.endIndex..<markdown.endIndex
    }

    private func makeChecklist() {
      let markdown = session.markdown
      let range = selectionRange(in: markdown)
      let start =
        markdown[..<range.lowerBound].lastIndex(where: \.isNewline)
        .map { markdown.index(after: $0) } ?? markdown.startIndex
      let end =
        range.upperBound > start && markdown[markdown.index(before: range.upperBound)].isNewline
        ? range.upperBound
        : markdown[range.upperBound...].firstIndex(where: \.isNewline) ?? markdown.endIndex
      let lines = start..<end
      let original = String(markdown[lines])
      let converted = MarkdownEditing.checklist(
        original, following: String(markdown[..<start]))
      if converted != original { replace(lines, with: converted, in: markdown) }
    }

    private func replace(_ range: Range<String.Index>, with text: String, in markdown: String) {
      let cursorOffset = range.lowerBound.utf16Offset(in: markdown) + text.utf16.count
      var updated = markdown
      updated.replaceSubrange(range, with: text)
      let cursor = String.Index(utf16Offset: cursorOffset, in: updated)
      session.markdown = updated
      selection = TextSelection(insertionPoint: cursor)
    }
  #endif
}
