import Foundation

enum PlanIdentity {
  static func preserve(in plan: inout DailyPlan, previous: DailyPlan) {
    let sectionIds = match(
      old: previous.sections, new: plan.sections,
      rules: [
        { $0.title == $1.title }, { $0.sourceLine == $1.sourceLine },
      ])
    var sectionMap: [UUID: UUID] = [:]
    for index in plan.sections.indices {
      let original = plan.sections[index].id
      let resolved = sectionIds[index] ?? original
      sectionMap[original] = resolved
      plan.sections[index].id = resolved
    }
    for index in plan.tasks.indices {
      plan.tasks[index].sectionId = plan.tasks[index].sectionId.flatMap { sectionMap[$0] }
    }
    let taskIds = match(
      old: previous.tasks, new: plan.tasks,
      rules: [
        { $0.title == $1.title && $0.sectionId == $1.sectionId },
        { $0.title == $1.title },
        { $0.sourceLine == $1.sourceLine && $0.sectionId == $1.sectionId },
      ])
    for index in plan.tasks.indices {
      plan.tasks[index].id = taskIds[index] ?? plan.tasks[index].id
    }
  }

  private static func match<Element: Identifiable>(
    old: [Element], new: [Element],
    rules: [(Element, Element) -> Bool]
  ) -> [UUID?] where Element.ID == UUID {
    var remaining = old
    var result = [UUID?](repeating: nil, count: new.count)
    for rule in rules {
      for index in new.indices where result[index] == nil {
        if let found = remaining.firstIndex(where: { rule($0, new[index]) }) {
          result[index] = remaining.remove(at: found).id
        }
      }
    }
    return result
  }
}
