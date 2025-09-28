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
    "Assign   -> name: Token, value: Expr",
    "Binary   -> left: Expr, `operator`: Token, right: Expr",
    "Call     -> callee: Expr, paren: Token, arguments: [Expr]",
    "Grouping -> expression: Expr",
    "Literal  -> value: Object",
    "Logical  -> left: Expr, `operator`: Token, right: Expr",
    "Unary    -> `operator`: Token, right: Expr",
    "Variable -> name: Token",
  ]
)
try defineAst(
  outputDir: outputDir,
  baseName: "Stmt",
  types: [
    "Block      -> statements: [Stmt]",
    "Expression -> expression: Expr",
    "If         -> condition: Expr, thenBranch: Stmt, elseBranch: Stmt?",
    "Print      -> expression: Expr",
    "Var        -> name: Token, initializer: Expr?",
    "While      -> condition: Expr, body: Stmt",
  ]
)

func defineAst(outputDir: String, baseName: String, types: [String]) throws {
  let path = outputDir + "/" + baseName + ".swift"
  var lines: [String] = ["// auto-generated code; do not manually modify\n"]
  lines.append(contentsOf: defineVisitor(baseName: baseName, types: types))
  lines.append("")
  lines.append("protocol \(baseName) {")
  lines.append("  func accept<R>(_ visitor: any \(baseName)Visitor<R>) throws -> R")
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
  let fields = fieldList.components(separatedBy: ", ")

  // Fields.
  for field in fields {
    lines.append("  let \(field)")
  }

  // Visitor pattern.
  lines.append("")
  lines.append("  func accept<R>(_ visitor: any \(baseName)Visitor<R>) throws -> R {")
  lines.append("    try visitor.visit\(className + baseName)(self)")
  lines.append("  }")

  lines.append("}")
  return lines
}

func defineVisitor(baseName: String, types: [String]) -> [String] {
  var lines: [String] = []
  lines.append("protocol \(baseName)Visitor<\(baseName)Result> {")
  lines.append("  associatedtype \(baseName)Result")

  for type in types {
    let typeName = type.components(separatedBy: "->")[0].trimmingCharacters(in: .whitespaces)
    lines.append("  func visit\(typeName + baseName)(_ \(baseName.lowercased()): \(typeName)) throws -> \(baseName)Result")
  }

  lines.append("}")
  return lines
}
