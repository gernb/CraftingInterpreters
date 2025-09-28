import Foundation

if CommandLine.arguments.count != 2 {
  print("Usage: generate_ast <output directory>")
  exit(64)
}

let outputDir = CommandLine.arguments[1]
try defineAst(
  outputDir: outputDir,
  baseName: "Expr",
  visitorGeneric: "R",
  types: [
    "Assign   -> name: Token, value: Expr",
    "Binary   -> left: Expr, `operator`: Token, right: Expr",
    "Grouping -> expression: Expr",
    "Literal  -> value: Object",
    "Unary    -> `operator`: Token, right: Expr",
    "Variable -> name: Token",
  ]
)
try defineAst(
  outputDir: outputDir,
  baseName: "Stmt",
  visitorGeneric: "S",
  types: [
    "Block      -> statements: [Stmt]",
    "Expression -> expression: Expr.Expr",
    "Print      -> expression: Expr.Expr",
    "Var        -> name: Token, initializer: Expr.Expr?",
  ]
)

func defineAst(outputDir: String, baseName: String, visitorGeneric: String, types: [String]) throws {
  let path = outputDir + "/" + baseName + ".swift"
  var lines: [String] = ["// auto-generated code; do not manually modify"]
  lines.append("")
  lines.append("enum \(baseName) {")
  lines.append(contentsOf: defineVisitor(baseName: baseName, visitorGeneric: visitorGeneric, types: types))
  lines.append("")
  lines.append("  protocol \(baseName) {")
  lines.append("    func accept<\(visitorGeneric)>(_ visitor: any Visitor<\(visitorGeneric)>) throws -> \(visitorGeneric)")
  lines.append("  }")

  // The AST classes.
  for type in types {
    let className = type.components(separatedBy: "->")[0].trimmingCharacters(in: .whitespaces)
    let fields = type.components(separatedBy: "->")[1].trimmingCharacters(in: .whitespaces)
    lines.append(contentsOf: defineType(baseName: baseName, visitorGeneric: visitorGeneric, className: className, fieldList: fields))
  }

  lines.append("}")

  try lines
    .joined(separator: "\n")
    .write(toFile: path, atomically: true, encoding: .utf8)
}

func defineType(baseName: String, visitorGeneric: String, className: String, fieldList: String) -> [String] {
  var lines: [String] = [""]
  lines.append("  struct \(className): \(baseName) {")
  let fields = fieldList.components(separatedBy: ", ")

  // Fields.
  for field in fields {
    lines.append("    let \(field)")
  }

  // Visitor pattern.
  lines.append("")
  lines.append("    func accept<\(visitorGeneric)>(_ visitor: any Visitor<\(visitorGeneric)>) throws -> \(visitorGeneric) {")
  lines.append("      try visitor.visit\(className + baseName)(self)")
  lines.append("    }")

  lines.append("  }")
  return lines
}

func defineVisitor(baseName: String, visitorGeneric: String, types: [String]) -> [String] {
  var lines: [String] = []
  lines.append("  protocol Visitor<\(visitorGeneric)> {")
  lines.append("    associatedtype \(visitorGeneric)")

  for type in types {
    let typeName = type.components(separatedBy: "->")[0].trimmingCharacters(in: .whitespaces)
    lines.append("    func visit\(typeName + baseName)(_ \(baseName.lowercased()): \(typeName)) throws -> \(visitorGeneric)")
  }

  lines.append("  }")
  return lines
}
