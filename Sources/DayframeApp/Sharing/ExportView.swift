import DayframeCore
import DayframeExport
import SwiftUI

struct ExportView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.locale) private var locale
  @State private var options: StoryOptions
  @State private var pages: [StoryPage] = []
  @State private var selectedPage = 0
  @State private var urls: [URL] = []
  @State private var document: PNGDocument?
  @State private var saving = false
  @State private var rendering = true
  @State private var error: String?
  @State private var showingError = false
  let plan: DailyPlan

  init(plan: DailyPlan) {
    self.plan = plan
    var initial = StoryOptions()
    initial.includedSections = Set(plan.sections.map(\.id))
    _options = State(initialValue: initial)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        ViewThatFits(in: .horizontal) {
          HStack(alignment: .top, spacing: 40) {
            StoryPreview(plan: plan, pages: pages, options: options, selectedPage: $selectedPage)
            ExportSettings(plan: plan, options: $options).frame(minWidth: 300)
          }.frame(minWidth: 640)
          VStack(spacing: 32) {
            StoryPreview(plan: plan, pages: pages, options: options, selectedPage: $selectedPage)
            ExportSettings(plan: plan, options: $options)
          }
        }
        .padding(DayframeStyle.margin)
      }
      .navigationTitle("Frame your day")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Done", action: close) }
        ToolbarItemGroup(placement: .primaryAction) {
          Button("Save PNG", systemImage: "square.and.arrow.down", action: savePNG)
            .disabled(rendering || urls.isEmpty)
          ShareLink(items: urls) { Label("Share", systemImage: "square.and.arrow.up") }
            .disabled(rendering || urls.isEmpty)
        }
      }
      .fileExporter(
        isPresented: $saving, document: document, contentType: .png,
        defaultFilename: "Dayframe-\(selectedPage + 1).png", onCompletion: receiveSave
      )
      .alert("Unable to export", isPresented: $showingError) {
      } message: {
        Text(error ?? "")
      }
      .onChange(of: options.template) { options.apply(options.template) }
      .task(id: options) { await render() }
    }
    .frame(idealWidth: 780, idealHeight: 780)
  }

  private func render() async {
    rendering = true
    do { try await Task.sleep(for: .milliseconds(150)) } catch { return }
    do {
      let newPages = StoryPaginator.pages(for: plan, options: options)
      let newURLs = try StoryRenderer.export(
        plan: plan, pages: newPages, options: options, locale: locale)
      pages = newPages
      selectedPage = min(selectedPage, max(0, pages.count - 1))
      urls = newURLs
      rendering = false
    } catch {
      rendering = false
      report(error)
    }
  }
  private func savePNG() {
    do {
      guard urls.indices.contains(selectedPage) else { return }
      document = PNGDocument(data: try Data(contentsOf: urls[selectedPage]))
      saving = true
    } catch { report(error) }
  }
  private func close() { dismiss() }
  private func receiveSave(_ result: Result<URL, Error>) {
    if case .failure(let error) = result { report(error) }
  }
  private func report(_ error: Error) {
    self.error = error.localizedDescription
    showingError = true
  }
}
