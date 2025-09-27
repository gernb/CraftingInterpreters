import Foundation

if CommandLine.arguments.count != 2 {
  print("Usage: generate_ast <output directory>")
  exit(64)
}

let outputDir = CommandLine.arguments[1]
try defineAst(
  outputDir: outputDir,
  baseName: "Expr",
  types: [
    "Binary   -> left: Expr, `operator`: Token, right: Expr",
    "Grouping -> expression: Expr",
    "Literal  -> value: Object?",
    "Unary    -> `operator`: Token, right: Expr",
  ]
)

func defineAst(outputDir: String, baseName: String, types: [String]) throws {
  let path = outputDir + "/" + baseName + ".swift"
  var lines: [String] = ["// auto-generated code; do not manually modify"]
  lines.append(contentsOf: defineVisitor(baseName: baseName, types: types))
  lines.append("")
  lines.append("protocol \(baseName) {")
  lines.append("  func accept<R>(_ visitor: any Visitor<R>) throws -> R")
  lines.append("}")

  // The AST classes.
  for type in types {
    let className = type.components(separatedBy: "->")[0].trimmingCharacters(in: .whitespaces)
    let fields = type.components(separatedBy: "->")[1].trimmingCharacters(in: .whitespaces)
    lines.append(contentsOf: defineType(baseName: baseName, className: className, fieldList: fields))
  }

  try lines
    .joined(separator: "\n")
    .write(toFile: path, atomically: true, encoding: .utf8)
}

func defineType(baseName: String, className: String, fieldList: String) -> [String] {
  var lines: [String] = [""]
  lines.append("struct \(className): \(baseName) {")

  // // Constructor.
  // lines.append("  init(\(fieldList)) {")

  // // Store parameters in fields.
  let fields = fieldList.components(separatedBy: ", ")
  // for field in fields {
  //   let name = field.components(separatedBy: ": ")[0]
  //   lines.append("    self.\(name) = \(name)")
  // }

  // lines.append("  }")

  // Fields.
  // lines.append("")
  for field in fields {
    lines.append("  let \(field)")
  }

  // Visitor pattern.
  lines.append("")
  lines.append("  func accept<R>(_ visitor: any Visitor<R>) throws -> R {")
  lines.append("    try visitor.visit\(className + baseName)(self)")
  lines.append("  }")

  lines.append("}")
  return lines
}

func defineVisitor(baseName: String, types: [String]) -> [String] {
  var lines: [String] = [""]
  lines.append("protocol Visitor<R> {")
  lines.append("  associatedtype R")

  for type in types {
    let typeName = type.components(separatedBy: "->")[0].trimmingCharacters(in: .whitespaces)
    lines.append("  func visit\(typeName + baseName)(_ \(baseName.lowercased()): \(typeName)) throws -> R")
  }

  lines.append("}")
  return lines
}
