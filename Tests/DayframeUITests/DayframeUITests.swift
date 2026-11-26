import XCTest

@MainActor
final class DayframeUITests: XCTestCase {
  func testAddCompleteAndPreviewExport() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    #if os(macOS)
      if !app.windows.firstMatch.waitForExistence(timeout: 2) {
        app.menuBars.menuBarItems["File"].click()
        app.menuItems["New Window"].click()
      }
    #endif
    let addButton = app.buttons["new-task"]
    XCTAssertTrue(addButton.waitForExistence(timeout: 10))
    activate(addButton)
    let field = app.descendants(matching: .any).matching(identifier: "task-title").firstMatch
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    activate(field)
    field.typeText("Read a book")
    activate(app.buttons["Save"])
    let completion = app.buttons["task-completion-Read a book"]
    XCTAssertTrue(completion.waitForExistence(timeout: 5))
    activate(completion)
    #if os(iOS)
      if app.segmentedControls.buttons["Markdown"].exists {
        app.segmentedControls.buttons["Markdown"].tap()
      }
    #endif
    let editor = app.textViews["markdown-editor"]
    XCTAssertTrue(editor.waitForExistence(timeout: 5))
    XCTAssertTrue((editor.value as? String)?.contains("- [x] Read a book") == true)
    activate(app.buttons["export-image"])
    XCTAssertTrue(app.buttons["Save PNG"].waitForExistence(timeout: 5))
    let enabled = NSPredicate(format: "enabled == true")
    expectation(for: enabled, evaluatedWith: app.buttons["Save PNG"])
    waitForExpectations(timeout: 10)
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Dayframe export"
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  func testSamplePlanWithLargeText() {
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--sample-plan", "-AppleLanguages", "(ja)",
      "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launch()
    XCTAssertTrue(app.buttons["new-task"].waitForExistence(timeout: 10))
    let completion = app.buttons["task-completion-Morning routine"]
    XCTAssertTrue(completion.waitForExistence(timeout: 5))
    #if os(iOS)
      for _ in 0..<4 where !completion.isHittable { app.swipeUp() }
    #endif
    XCTAssertTrue(completion.isHittable)
    activate(completion)
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Dayframe Japanese Dynamic Type"
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func activate(_ element: XCUIElement) {
    #if os(macOS)
      element.click()
    #else
      element.tap()
    #endif
  }
}
