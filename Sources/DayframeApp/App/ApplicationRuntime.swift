import DayframeCore
import SwiftData
import SwiftUI

@MainActor @Observable
final class ApplicationRuntime {
  private(set) var storage: StorageBootstrap?
  private(set) var sync: SyncMonitor?
  var error: String?

  func open() {
    guard storage == nil, error == nil else { return }
    do {
      let testing = ProcessInfo.processInfo.arguments.contains("--ui-testing")
      let base = testing ? URL.temporaryDirectory : URL.applicationSupportDirectory
      let directory = base.appending(
        path: testing ? "Dayframe-Test-\(UUID())" : "Dayframe", directoryHint: .isDirectory)
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      let configured = Bundle.main.object(forInfoDictionaryKey: "DayframeCloudContainer") as? String
      let identifier =
        testing ? nil : configured.flatMap { $0.isEmpty || $0.hasPrefix("$(") ? nil : $0 }
      let result = try StorageBootstrap.open(
        at: directory.appending(path: "Dayframe.store"), cloudIdentifier: identifier)
      sync = SyncMonitor(
        cloudIdentifier: result.cloudEnabled ? identifier : nil, startupFailure: result.cloudFailure
      )
      storage = result
      if testing && ProcessInfo.processInfo.arguments.contains("--sample-plan") {
        try seedSample(result)
      }
    } catch { self.error = error.localizedDescription }
  }

  func retry() {
    error = nil
    open()
  }

  private func seedSample(_ storage: StorageBootstrap) throws {
    guard let url = Bundle.main.url(forResource: "Example", withExtension: "md") else { return }
    let source = try String(contentsOf: url, encoding: .utf8)
    let today = DayRecord.key(for: .now)
    let markdown = source.replacing("# 2026-11-26", with: "# \(today)")
    let repository = DayRepository(context: storage.container.mainContext)
    let record = try repository.day(for: .now)
    try repository.save(
      record, markdown: markdown, plan: MarkdownParser.parse(markdown, date: .now, dayId: record.id)
    )
  }
}
