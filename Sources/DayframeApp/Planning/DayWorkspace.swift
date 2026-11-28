import DayframeCore
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct DayWorkspace: View {
  @Environment(\.scenePhase) private var scenePhase
  @State private var session: EditorSession
  @State private var mode: EditorMode = .plan
  @State private var taskDraft: TaskDraft?
  @State private var showingSection = false
  @State private var editingSection: PlanSection?
  @State private var showingExport = false
  @State private var importing = false
  @State private var exportingMarkdown = false
  @State private var importedMarkdown: String?
  @State private var showingError = false
  @State private var showingRecovery = false

  init(record: DayRecord, context: ModelContext) {
    _session = State(initialValue: EditorSession(record: record, context: context))
  }

  var body: some View {
    WorkspaceLayout(session: session, mode: $mode, edit: edit)
      .navigationTitle("Dayframe")
      .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
          Button("New task", systemImage: "plus", action: addTask).keyboardShortcut("n")
            .accessibilityIdentifier("new-task")
          Button("Export image", systemImage: "square.and.arrow.up", action: exportImage)
            .accessibilityIdentifier("export-image")
            .keyboardShortcut("e", modifiers: [.command, .shift])
        }
        #if os(iOS)
          ToolbarOverflowMenu {
            WorkspaceActions(
              session: session, addSection: addSection, editSection: editSection,
              importMarkdown: importMarkdown, exportMarkdown: exportMarkdown,
              showRecovery: showRecovery)
          }
        #else
          ToolbarItem {
            Menu("Plan actions", systemImage: "ellipsis.circle") {
              WorkspaceActions(
                session: session, addSection: addSection, editSection: editSection,
                importMarkdown: importMarkdown, exportMarkdown: exportMarkdown,
                showRecovery: showRecovery)
            }
          }
        #endif
      }
      .sheet(item: $taskDraft) { draft in TaskEditor(draft: draft, session: session) }
      .sheet(isPresented: $showingSection) {
        SectionEditor(section: editingSection, session: session)
      }
      .sheet(isPresented: $showingExport) {
        ExportView(plan: session.plan, markdown: session.markdown)
      }
      .sheet(isPresented: $showingRecovery) { RecoveryView(session: session) }
      .fileImporter(
        isPresented: $importing, allowedContentTypes: [.plainText, .text],
        onCompletion: receiveImport
      )
      .fileExporter(
        isPresented: $exportingMarkdown, document: MarkdownDocument(text: session.markdown),
        contentType: UTType(filenameExtension: "md") ?? .plainText,
        defaultFilename: "Dayframe-\(session.record.dayKey).md", onCompletion: receiveExport
      )
      .confirmationDialog("Replace this plan?", item: $importedMarkdown) { markdown in
        Button("Replace Markdown", role: .destructive, action: { replaceImport(markdown) })
      }
      .alert("Unable to complete action", isPresented: $showingError) {
      } message: {
        Text(session.error ?? "")
      }
      .onChange(of: session.markdown) { session.reparse() }
      .onChange(of: session.record.markdown) { session.receiveRecordChange() }
      .onChange(of: session.error) { showingError = session.error != nil }
      .onChange(of: scenePhase) { if scenePhase != .active { session.save() } }
      .task(id: session.markdown) { await session.saveAfterPause() }
      .onDisappear(perform: session.save)
  }

  private func addTask() { taskDraft = TaskDraft() }
  private func edit(_ task: PlanTask) { taskDraft = TaskDraft(task: task) }
  private func addSection() {
    editingSection = nil
    showingSection = true
  }
  private func editSection(_ section: PlanSection) {
    editingSection = section
    showingSection = true
  }
  private func exportImage() {
    session.save()
    showingExport = true
  }
  private func importMarkdown() { importing = true }
  private func exportMarkdown() {
    session.save()
    exportingMarkdown = true
  }
  private func showRecovery() { showingRecovery = true }
  private func replaceImport(_ markdown: String) {
    do {
      try RecoveryArchive.save(session.markdown, dayKey: session.record.dayKey)
      session.setMarkdown(markdown)
      session.save()
    } catch { session.error = error.localizedDescription }
  }
  private func receiveImport(_ result: Result<URL, Error>) {
    do {
      let url = try result.get()
      let access = url.startAccessingSecurityScopedResource()
      defer { if access { url.stopAccessingSecurityScopedResource() } }
      importedMarkdown = try String(contentsOf: url, encoding: .utf8)
    } catch { session.error = error.localizedDescription }
  }
  private func receiveExport(_ result: Result<URL, Error>) {
    if case .failure(let error) = result { session.error = error.localizedDescription }
  }
}
