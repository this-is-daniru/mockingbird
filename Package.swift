// swift-tools-version:5.5
import PackageDescription
import class Foundation.ProcessInfo

/// The manifest is split into several sub-packages based on build type. It's a slight hack, but
/// does offer a few advantages until SPM evolves, such as no package dependencies when consuming
/// just the framework product, target-specific platform requirements, and SwiftUI compatibility.
let package: Package
  // MARK: Executables
  package = Package(
    name: "Mockingbird",
    platforms: [
      .macOS(.v12),
    ],
    products: [
      .executable(name: "mockingbird", targets: ["MockingbirdCli"]),
      .executable(name: "automation", targets: ["MockingbirdAutomationCli"]),
    ],
    // These dependencies must be kept in sync with the Xcode project.
    // TODO: Add a build rule to enforce consistency.
    dependencies: [
      .package(url: "https://github.com/apple/swift-argument-parser.git", .exact("1.1.3")),
      .package(url: "https://github.com/kylef/PathKit.git", .exact("1.0.1")),
      .package(name: "SwiftSyntax", url: "https://github.com/swiftlang/swift-syntax", .exact("508.0.0")),
      .package(url: "https://github.com/jpsim/SourceKitten.git", .exact("0.33.0")),
      .package(url: "https://github.com/tuist/XcodeProj.git", .exact("8.7.1")),
      .package(url: "https://github.com/weichsel/ZIPFoundation.git", .exact("0.9.14")),
    ],
    targets: [
      .target(name: "MockingbirdCommon"),
      .target(
        name: "MockingbirdCli",
        dependencies: [
          .product(name: "ArgumentParser", package: "swift-argument-parser"),
          "MockingbirdCommon",
          "MockingbirdGenerator",
          "XcodeProj",
          "ZIPFoundation",
        ],
        linkerSettings: [
          .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path"]),
          .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/Libraries"]),
        ]),
      .target(
        name: "MockingbirdGenerator",
        dependencies: [
          .product(name: "SourceKittenFramework", package: "SourceKitten"),
          "MockingbirdCommon",
          "SwiftSyntax",
          "XcodeProj",
          .product(name: "SwiftSyntaxParser", package: "SwiftSyntax"),
        ]),
      .target(
        name: "MockingbirdAutomationCli",
        dependencies: [
          .product(name: "ArgumentParser", package: "swift-argument-parser"),
          "MockingbirdAutomation",
          "MockingbirdCommon",
          "PathKit",
        ]),
      .target(
        name: "MockingbirdAutomation",
        dependencies: [
          "MockingbirdCommon",
          "PathKit",
        ]),
      .testTarget(
        name: "MockingbirdAutomationTests",
        dependencies: ["MockingbirdAutomation"]),
    ]
  )
