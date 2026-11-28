import DayframeExport
import SwiftUI

struct ExportTextSizes: View {
  @Binding var options: StoryOptions

  var body: some View {
    VStack(alignment: .leading, spacing: DayframeStyle.spacing) {
      LabeledContent {
        Text(options.textScale, format: .percent.precision(.fractionLength(0)))
      } label: {
        Text("Task text size")
      }
      Slider(value: $options.textScale, in: StoryOptions.textScaleRange, step: 0.05) {
        Text("Task text size")
      }
      .accessibilityValue(options.textScale.formatted(.percent.precision(.fractionLength(0))))
      .accessibilityIdentifier("story-task-text-size")

      LabeledContent {
        Text(options.dateScale, format: .percent.precision(.fractionLength(0)))
      } label: {
        Text("Date heading size")
      }
      Slider(value: $options.dateScale, in: StoryOptions.dateScaleRange, step: 0.05) {
        Text("Date heading size")
      }
      .accessibilityValue(options.dateScale.formatted(.percent.precision(.fractionLength(0))))
      .accessibilityIdentifier("story-date-heading-size")
    }
  }
}
