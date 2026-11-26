import Foundation
import SwiftData

@MainActor
public struct StorageBootstrap {
  public let container: ModelContainer
  public let cloudEnabled: Bool
  public let cloudFailure: String?

  public static func open(at url: URL, cloudIdentifier: String?) throws -> StorageBootstrap {
    let schema = Schema([DayRecord.self])
    if let cloudIdentifier {
      do {
        let configuration = ModelConfiguration(
          schema: schema, url: url,
          cloudKitDatabase: .private(cloudIdentifier))
        return try StorageBootstrap(
          container: ModelContainer(for: schema, configurations: configuration),
          cloudEnabled: true, cloudFailure: nil)
      } catch {
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        return try StorageBootstrap(
          container: ModelContainer(for: schema, configurations: configuration),
          cloudEnabled: false, cloudFailure: error.localizedDescription)
      }
    }
    let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
    return try StorageBootstrap(
      container: ModelContainer(for: schema, configurations: configuration),
      cloudEnabled: false, cloudFailure: nil)
  }
}
