// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "CraftingInterpreters",
  products: [
    .executable(name: "jlox", targets: ["jlox"]),
    .executable(name: "clox", targets: ["clox"]),
  ],
  targets: [
    .executableTarget(
      name: "jlox"
    ),
    .executableTarget(
      name: "clox"
    ),
  ]
)
