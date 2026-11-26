import Foundation

public struct RecoveryDraft: Identifiable, Equatable, Sendable {
  public let url: URL
  public let dayKey: String
  public let createdAt: Date
  public var id: URL { url }
}
