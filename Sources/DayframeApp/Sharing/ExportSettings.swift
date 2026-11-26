import DayframeCore
import DayframeExport
import SwiftUI

struct ExportSettings: View {
  let plan: DailyPlan
  @Binding var options: StoryOptions

  var body: some View {
    VStack(alignment: .leading, spacing: DayframeStyle.spacing) {
      Picker("Template", selection: $options.template) {
        ForEach(StoryTemplate.allCases) { template in Text(template.rawValue).tag(template) }
      }
      .pickerStyle(.segmented)
      ColorPicker("Background", selection: $options.background, supportsOpacity: false)
      ColorPicker("Text color", selection: $options.foreground, supportsOpacity: false)
      Picker("Font", selection: $options.font) {
        ForEach(StoryFont.allCases) { font in Text(LocalizedStringKey(font.rawValue)).tag(font) }
      }
      Picker("Date format", selection: $options.dateStyle) {
        ForEach(StoryDateStyle.allCases) { style in
          Text(LocalizedStringKey(style.rawValue)).tag(style)
        }
      }
      Divider()
      Toggle("Completed tasks", isOn: $options.showCompleted)
      Toggle("Completion count", isOn: $options.showProgress)
      Toggle("Dayframe signature", isOn: $options.showBranding)
      Divider()
      Text("Sections").font(.headline)
      Toggle("Unsectioned", isOn: $options.showUnsectioned)
      ForEach(plan.sections) { section in
        Toggle(section.title, isOn: sectionBinding(section.id))
      }
    }
    .frame(maxWidth: 380, alignment: .leading)
  }

  private func sectionBinding(_ id: UUID) -> Binding<Bool> {
    Binding(
      get: { options.includedSections.contains(id) },
      set: { selected in
        if selected {
          options.includedSections.insert(id)
        } else {
          options.includedSections.remove(id)
        }
      })
  }
}
