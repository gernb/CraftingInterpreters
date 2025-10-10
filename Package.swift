// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "CraftingInterpreters",
  platforms: [
    .macOS(.v26),
  ],
  products: [
    .executable(name: "jlox", targets: ["jlox"]),
    .executable(name: "clox", targets: ["clox"]),
  ],
  traits: [
    .default(
      enabledTraits: [
        "TraceExecution", "PrintCode",
      ]
    ),
    .init(
      name: "TraceExecution",
      description: "Log execution tracing messages.",
      enabledTraits: []
    ),
    .init(
      name: "PrintCode",
      description: "Print compiled code as disassembly.",
      enabledTraits: []
    ),
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
