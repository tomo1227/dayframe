import Foundation

public enum RecoveryArchive {
  public static var directory: URL {
    URL.applicationSupportDirectory.appending(
      path: "Dayframe/Recovered", directoryHint: .isDirectory)
  }

  @discardableResult
  public static func save(_ markdown: String, dayKey: String, directory: URL = directory) throws
    -> URL
  {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appending(path: "\(dayKey)_\(UUID()).md")
    try markdown.write(to: url, atomically: true, encoding: .utf8)
    return url
  }

  public static func drafts(directory: URL = directory) throws -> [RecoveryDraft] {
    guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
    let urls = try FileManager.default.contentsOfDirectory(
      at: directory, includingPropertiesForKeys: [.creationDateKey])
    return try urls.filter { $0.pathExtension == "md" }.map { url in
      let created = try url.resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast
      let key = String(url.lastPathComponent.split(separator: "_").first ?? "")
      return RecoveryDraft(url: url, dayKey: key, createdAt: created)
    }.sorted { $0.createdAt > $1.createdAt }
  }
}
