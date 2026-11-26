import DayframeCore
import SwiftUI

struct RecoveryView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var drafts: [RecoveryDraft] = []
  @State private var pendingRestore: RecoveryDraft?
  @State private var error: String?
  @State private var showingError = false
  let session: EditorSession

  var body: some View {
    NavigationStack {
      List(drafts) { draft in
        VStack(alignment: .leading, spacing: 12) {
          Text(draft.dayKey).font(.headline)
          Text(draft.createdAt, format: .dateTime.month().day().hour().minute()).foregroundStyle(
            .secondary)
          HStack {
            Button(
              "Restore", systemImage: "arrow.counterclockwise", action: { pendingRestore = draft })
            Spacer()
            ShareLink(item: draft.url) { Label("Share", systemImage: "square.and.arrow.up") }
          }
        }
        .padding(.vertical, 8)
      }
      .overlay {
        if drafts.isEmpty {
          ContentUnavailableView("No recovered drafts", systemImage: "clock.arrow.circlepath")
        }
      }
      .navigationTitle("Recovered drafts")
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done", action: close) } }
      .confirmationDialog("Restore this draft?", item: $pendingRestore) { draft in
        Button("Restore", action: { restore(draft) })
      }
      .alert("Unable to complete action", isPresented: $showingError) {
      } message: {
        Text(error ?? "")
      }
      .task { load() }
    }
    .frame(idealWidth: 480, idealHeight: 480)
  }

  private func load() {
    do { drafts = try RecoveryArchive.drafts() } catch { report(error) }
  }
  private func restore(_ draft: RecoveryDraft) {
    do {
      let markdown = try String(contentsOf: draft.url, encoding: .utf8)
      try RecoveryArchive.save(session.markdown, dayKey: session.record.dayKey)
      session.setMarkdown(markdown)
      session.save()
      dismiss()
    } catch { report(error) }
  }
  private func close() { dismiss() }
  private func report(_ error: Error) {
    self.error = error.localizedDescription
    showingError = true
  }
}
