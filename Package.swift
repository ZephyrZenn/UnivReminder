// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "UnivReminder",
  platforms: [.macOS(.v12)],
  dependencies: [
    .package(url: "https://github.com/thebarndog/swift-dotenv.git", .upToNextMajor(from: "2.0.0"))
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .executableTarget(
      name: "UnivReminder",
      dependencies: [
        .product(name: "SwiftDotenv", package: "swift-dotenv")
      ],
      path: "Sources"),
  ]
)
