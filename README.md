<p align="center">
  <img src="/Sources/Documentation/Mockingbird.docc/Resources/logo@3x.png" alt="Mockingbird - Swift Mocking Framework" width="150">
  <h1 align="center">Mockingbird</h1>
</p>

<p align="center">
  <a href="#quick-start"><img src="https://img.shields.io/badge/package-CocoaPods%20%7C%20Carthage%20%7C%20SwiftPM-4BC51D.svg" alt="Package managers"></a>
  <a href="https://github.com/birdrides/mockingbird/blob/master/LICENSE.md"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT licensed"></a>
  <a href="https://join.slack.com/t/birdopensource/shared_invite/zt-wogxij50-3ZM7F8ZxFXvPkE0j8xTtmw" rel="nofollow"><img src="https://img.shields.io/badge/slack-%23mockingbird-A417A6.svg" alt="#mockingbird Slack channel"></a>
</p>

Mockingbird makes it easy to mock, stub, and verify objects in Swift unit tests. You can test both Swift and Objective-C without writing any boilerplate or modifying production code.

## Documentation

Visit [MockingbirdSwift.com](https://mockingbirdswift.com) for quick start guides, walkthroughs, and API reference articles.

## Examples

Using Mockingbird in tests.

```swift
// Mocking
let bird = mock(Bird.self)

// Stubbing
given(bird.canFly).willReturn(true)

// Verification
verify(bird.fly()).wasCalled()
```

## Plugin

```swift
        .binaryTarget(
            name: "MockingbirdBinary",
            url: "https://github.com/this-is-daniru/mockingbird/releases/download/0.20.0n/mockingbird-0.20.0n.artifactbundle.zip",
            checksum: "bc7162c9b68df4bebcfdbef29dd77f0eef06c94d50f0922ee85bf34ad1b2994c"
        ),
        .plugin(
            name: "GenerateMocks",
            capability: .command(
                intent: .custom(
                    verb: "Mockingbird-command",
                    description: "Mockingbird Generate Mocks"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Generate files to package directory")
                ]
            ),
            dependencies: [.target(name: "MockingbirdBinary")]
        ),
```

```swift
import Foundation
import PackagePlugin

@main
struct GenerateMocks: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) throws {
        for target in context.package.targets {
            guard let target = target as? SourceModuleTarget,
                  !target.name.contains("Mock"),
                  !target.name.contains("Tests")
            else { continue }

            try preparePackageDescription(for: target)
            try generateMockFile(for: target, context: context)
        }
    }

    func preparePackageDescription(for target: Target) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "xcrun --sdk macosx swift package --disable-sandbox describe --type json > project.json"]
        try process.run()
        process.waitUntilExit()
        try verifyResult(
            from: process,
            target: target,
            errorMessage: "Failed to prepare package description for"
        )
    }

    func generateMockFile(for target: Target, context: PluginContext) throws {
        let mockingbird = try context.tool(named: "Mockingbird")
        let mockingbirdUrl = URL(fileURLWithPath: mockingbird.path.string)
        let arguments = [
                "generate",
                "--project", "project.json",
                "--output-dir", "Sources/\(target.name)Mock/MockingbirdMocks",
                "--testbundle", "\(target.name)Tests",
                "--targets", "\(target.name)",
                "--verbose",
                "--diagnostics", "all"
            ]

        let process = Process()
        process.executableURL = mockingbirdUrl
        process.arguments = arguments

        try process.run()
        process.waitUntilExit()
        try verifyResult(
            from: process,
            target: target,
            errorMessage: "Failed to generate mocks"
        )
    }

    func verifyResult(from process: Process, target: Target, errorMessage: String) throws {
        if process.terminationReason == .exit && process.terminationStatus == 0 {
            print("Generated mocks for \(target.name).")
        } else {
            let problem = "\(process.terminationReason):\(process.terminationStatus)"
            throw "\(errorMessage) for \(target.name).\n\(problem)"
        }
    }
}

extension String: @retroactive LocalizedError {
    public var errorDescription: String? { self }
}

```

## Building the executable binary

```console
swift build --product mockingbird --configuration release
```

## Checksum

```console
cd mockingbird
touch Package.swift
swift package compute-checksum mockingbird-0.20.0n.artifactbundle.zip
```

## License

Mockingbird is [MIT licensed](/LICENSE.md). By contributing to Mockingbird, you agree that your contributions will be licensed under its MIT license.
