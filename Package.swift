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
    .library(
      name: "SoddyHexletModel",
      targets: ["SoddyHexletModel"]),
    .library(
      name: "SoddyHexletUI",
      targets: ["SoddyHexletUI"]),
  ],
  targets: [
    .target(
      name: "SteinerCircleModel"),
    .target(
      name: "SteinerCircleUI",
      dependencies: ["SteinerCircleModel"]),
    .target(
      name: "SoddyHexletModel",
      dependencies: ["SteinerCircleModel"]),
    .target(
      name: "SoddyHexletUI",
      dependencies: ["SoddyHexletModel"]),
    .testTarget(
      name: "SteinerCircleModelTests",
      dependencies: ["SteinerCircleModel"]),
    .testTarget(
      name: "SoddyHexletModelTests",
      dependencies: ["SoddyHexletModel"]),
  ]
)
