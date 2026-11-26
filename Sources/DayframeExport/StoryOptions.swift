import Foundation
import SwiftUI

public struct StoryOptions: Equatable {
  public var template: StoryTemplate = .editorial
  public var background: Color = .white
  public var foreground: Color = Color(red: 0.12, green: 0.12, blue: 0.12)
  public var font: StoryFont = .serif
  public var showCompleted: Bool = true
  public var showProgress: Bool = true
  public var showBranding: Bool = true
  public var includedSections: Set<UUID> = []
  public var showUnsectioned: Bool = true
  public var dateStyle: StoryDateStyle = .full

  public init() {}
  public mutating func apply(_ template: StoryTemplate) {
    self.template = template
    background = template.background
    foreground = template.foreground
    font = template == .minimal ? .sans : .serif
  }
}
