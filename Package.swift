// swift-tools-version: 6.4
import PackageDescription

let package = Package(
  name: "Dayframe",
  defaultLocalization: "en",
  platforms: [.macOS(.v27), .iOS(.v27)],
  products: [
    .library(name: "DayframeCore", targets: ["DayframeCore"]),
    .library(name: "DayframeExport", targets: ["DayframeExport"]),
    .executable(name: "DayframeDesktop", targets: ["DayframeApp"]),
  ],
  targets: [
    .target(name: "DayframeCore"),
    .target(name: "DayframeExport", dependencies: ["DayframeCore"]),
    .executableTarget(name: "DayframeApp", dependencies: ["DayframeCore", "DayframeExport"]),
    .testTarget(name: "DayframeCoreTests", dependencies: ["DayframeCore", "DayframeExport"]),
  ]
)
