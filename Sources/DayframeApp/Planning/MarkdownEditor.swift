import SwiftUI

struct MarkdownEditor: View {
  @Bindable var session: EditorSession

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Label("Markdown", systemImage: "text.alignleft")
        .font(.headline).padding(DayframeStyle.spacing)
      Divider()
      TextEditor(text: $session.markdown)
        .font(.body.monospaced()).padding(12)
        .autocorrectionDisabled()
        .accessibilityLabel("Daily plan Markdown")
        .accessibilityIdentifier("markdown-editor")
    }
  }
}
