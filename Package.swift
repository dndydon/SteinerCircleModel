// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "SteinerCircleModel",
  platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17), .watchOS(.v10), .visionOS(.v1)],
  products: [
    .library(
      name: "SteinerCircleModel",
      targets: ["SteinerCircleModel"]),
    .library(
      name: "SteinerCircleUI",
      targets: ["SteinerCircleUI"]),
  ],
  targets: [
    .target(
      name: "SteinerCircleModel"),
    .target(
      name: "SteinerCircleUI",
      dependencies: ["SteinerCircleModel"]),
    .testTarget(
      name: "SteinerCircleModelTests",
      dependencies: ["SteinerCircleModel"]),
  ]
)
