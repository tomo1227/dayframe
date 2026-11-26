import Foundation

public struct DailyPlan: Equatable, Sendable, Codable {
  public var id: UUID
  public var title: String
  public var date: Date
  public var tasks: [PlanTask]
  public var sections: [PlanSection]
  public var completedCount: Int { tasks.count(where: \.isCompleted) }
  public var progress: Double { tasks.isEmpty ? 0 : Double(completedCount) / Double(tasks.count) }
}
