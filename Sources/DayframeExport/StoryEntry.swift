import Foundation

public struct StoryEntry: Identifiable, Equatable, Sendable {
  public let id: String
  public let title: String
  public let description: String
  public let section: String?
  public let time: String?
  public let isCompleted: Bool
  public let isContinuation: Bool
  public let height: Double
}
