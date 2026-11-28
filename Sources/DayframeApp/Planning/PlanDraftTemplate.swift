import Foundation

enum PlanDraftTemplate: String, CaseIterable, Identifiable {
  case blank, daily, work

  var id: Self { self }

  var title: LocalizedStringResource {
    switch self {
    case .blank: "Date only"
    case .daily: "Morning, afternoon, evening"
    case .work: "Work priorities"
    }
  }

  func body(locale: Locale) -> String {
    let sections: [LocalizedStringResource] =
      switch self {
      case .blank: []
      case .daily: ["Morning", "Afternoon", "Evening"]
      case .work: ["Priorities", "Meetings", "Follow-up"]
      }
    return sections.map { section in
      var section = section
      section.locale = locale
      return "## \(String(localized: section))\n"
    }.joined(separator: "\n")
  }
}
