import Foundation
import SwiftData

@MainActor
public struct StorageBootstrap {
  public let container: ModelContainer

  public static func open(at url: URL) throws -> StorageBootstrap {
    let schema = Schema([DayRecord.self])
    let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
    return try StorageBootstrap(
      container: ModelContainer(for: schema, configurations: configuration))
  }
}
