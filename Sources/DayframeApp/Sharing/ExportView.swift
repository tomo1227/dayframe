import DayframeCore
import DayframeExport
import SwiftUI

struct ExportView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.locale) private var locale
  @AppStorage("preferredStoryTemplate") private var preferredTemplate: StoryTemplate = .editorial
  @State private var options: StoryOptions
  @State private var renderedOptions: StoryOptions?
  @State private var pages: [StoryPage] = []
  @State private var selectedPage = 0
  @State private var urls: [URL] = []
  @State private var document: PNGDocument?
  @State private var saving = false
  @State private var error: String?
  @State private var showingError = false
  let plan: DailyPlan
  let markdown: String

  init(plan: DailyPlan, markdown: String) {
    self.plan = plan
    self.markdown = markdown
    var initial = StoryOptions()
    initial.includedSections = Set(plan.sections.map(\.id))
    _options = State(initialValue: initial)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        ViewThatFits(in: .horizontal) {
          HStack(alignment: .top, spacing: 40) {
            preview
            settings.frame(minWidth: 300)
          }.frame(minWidth: 640)
          VStack(spacing: 32) {
            preview
            settings
          }
        }
        .padding(DayframeStyle.margin)
      }
      .navigationTitle("Frame your day")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Done", action: close) }
        ToolbarItemGroup(placement: .primaryAction) {
          Button("Save PNG", systemImage: "square.and.arrow.down", action: savePNG)
            .disabled(!canExport)
          ShareLink(items: urls) { Label("Share", systemImage: "square.and.arrow.up") }
            .disabled(!canExport)
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
      .onAppear { options.apply(preferredTemplate) }
      .onChange(of: options.template) {
        preferredTemplate = options.template
        options.apply(options.template)
      }
      .task(id: options) { await render() }
    }
    .frame(idealWidth: 780, idealHeight: 780)
  }

  private var canExport: Bool { renderedOptions == options && !urls.isEmpty }

  private var preview: some View {
    let matchesRatio = renderedOptions?.aspectRatio == options.aspectRatio
    return StoryPreview(
      plan: plan, pages: matchesRatio ? pages : [],
      options: matchesRatio ? renderedOptions ?? options : options, selectedPage: $selectedPage)
  }

  private var settings: some View {
    VStack(alignment: .leading, spacing: DayframeStyle.spacing) {
      Picker("Aspect ratio", selection: $options.aspectRatio) {
        ForEach(StoryAspectRatio.allCases) { ratio in
          Text(verbatim: ratio.rawValue).tag(ratio)
        }
      }
      .pickerStyle(.menu)
      ExportTextSizes(options: $options)
      ExportSettings(plan: plan, options: $options)
    }
  }

  private func render() async {
    do { try await Task.sleep(for: .milliseconds(150)) } catch { return }
    do {
      let newPages = StoryPaginator.pages(for: plan, options: options, markdown: markdown)
      let newURLs = try StoryRenderer.export(
        plan: plan, pages: newPages, options: options, locale: locale)
      pages = newPages
      selectedPage = min(selectedPage, max(0, pages.count - 1))
      urls = newURLs
      renderedOptions = options
    } catch {
      report(error)
    }
  }
  private func savePNG() {
    do {
      guard canExport, urls.indices.contains(selectedPage) else { return }
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
