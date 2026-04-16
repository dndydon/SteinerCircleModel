// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "SteinerCircleModel",
  platforms: [.macOS(.v14)],
  products: [
    .library(
      name: "SteinerCircleModel",
      targets: ["SteinerCircleModel"]),
  ],
  targets: [
    .target(
      name: "SteinerCircleModel"),
    .testTarget(
      name: "SteinerCircleModelTests",
      dependencies: ["SteinerCircleModel"]),
  ]
)
