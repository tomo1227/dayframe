import SwiftUI

enum DayframeAppearance: String, CaseIterable, Identifiable {
  case system, light, dark

  var id: Self { self }

  var title: LocalizedStringResource {
    switch self {
    case .system: "Match system appearance"
    case .light: "Light appearance"
    case .dark: "Dark appearance"
    }
  }

  var colorScheme: ColorScheme? {
    switch self {
    case .system: nil
    case .light: .light
    case .dark: .dark
    }
  }
}
