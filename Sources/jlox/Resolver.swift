final class Resolver: ExprVisitor, StmtVisitor {
  private enum FunctionType {
    case none, function, initializer, method
  }
  private enum ClassType {
    case none, `class`
  }

  private let interpreter: Interpreter
  private var scopes: [[String: Bool]] = []
  private var currentFunction: FunctionType = .none
  private var currentClass: ClassType = .none

  init(using interpreter: Interpreter) {
    self.interpreter = interpreter
  }

  func resolve(_ statements: [Stmt]) throws {
    for statement in statements {
      try resolve(statement)
    }
  }

  func visitBlockStmt(_ stmt: Block) throws {
    beginScope()
    try resolve(stmt.statements)
    endScope()
  }

  func visitClassStmt(_ stmt: Class) throws {
    let enclosingClass = currentClass
    currentClass = .class

    declare(stmt.name)
    define(stmt.name)

    beginScope()
    let lastIndex = scopes.endIndex - 1
    scopes[lastIndex]["this"] = true

    for method in stmt.methods {
      let declaration: FunctionType = method.name.lexeme == "init" ? .initializer : .method
      try resolveFunction(method, type: declaration)
    }

    endScope()
    currentClass = enclosingClass
  }

  func visitExpressionStmt(_ stmt: Expression) throws {
    try resolve(stmt.expression)
  }

  func visitFunctionStmt(_ stmt: Function) throws {
    declare(stmt.name)
    define(stmt.name)
    try resolveFunction(stmt, type: .function)
  }

  func visitIfStmt(_ stmt: If) throws {
    try resolve(stmt.condition)
    try resolve(stmt.thenBranch)
    if let elseBranch = stmt.elseBranch {
      try resolve(elseBranch)
    }
  }

  func visitPrintStmt(_ stmt: Print) throws {
    try resolve(stmt.expression)
  }

  func visitReturnStmt(_ stmt: Return) throws {
    if currentFunction == .none {
      Lox.error(token: stmt.keyword, message: "Can't return from top-level code.")
    }
    if let value = stmt.value {
      if currentFunction == .initializer {
        Lox.error(token: stmt.keyword, message: "Can't return a value from an initializer.")
      }
      try resolve(value)
    }
  }

  func visitVarStmt(_ stmt: Var) throws {
    declare(stmt.name)
    if let initializer = stmt.initializer {
      try resolve(initializer)
    }
    define(stmt.name)
  }

  func visitWhileStmt(_ stmt: While) throws {
    try resolve(stmt.condition)
    try resolve(stmt.body)
  }

  func visitAssignExpr(_ expr: Assign) throws {
    try resolve(expr.value)
    try resolveLocal(expr: expr, name: expr.name)
  }

  func visitBinaryExpr(_ expr: Binary) throws {
    try resolve(expr.left)
    try resolve(expr.right)
  }

  func visitCallExpr(_ expr: Call) throws {
    try resolve(expr.callee)
    for argument in expr.arguments {
      try resolve(argument)
    }
  }

  func visitGetExpr(_ expr: Get) throws {
    try resolve(expr.object)
  }

  func visitGroupingExpr(_ expr: Grouping) throws {
    try resolve(expr.expression)
  }

  func visitLiteralExpr(_ expr: Literal) throws {
    // no-op
  }

  func visitLogicalExpr(_ expr: Logical) throws {
    try resolve(expr.left)
    try resolve(expr.right)
  }

  func visitSetExpr(_ expr: Set) throws {
    try resolve(expr.value)
    try resolve(expr.object)
  }

  func visitThisExpr(_ expr: This) throws {
    guard currentClass != .none else {
      Lox.error(token: expr.keyword, message: "Can't use 'this' outside of a class.")
      return
    }
    try resolveLocal(expr: expr, name: expr.keyword)
  }

  func visitUnaryExpr(_ expr: Unary) throws {
    try resolve(expr.right)
  }

  func visitVariableExpr(_ expr: Variable) throws {
    if scopes.isEmpty == false && scopes.last![expr.name.lexeme] == false {
      Lox.error(token: expr.name, message: "Can't read local variable in its own initializer.")
    }
    try resolveLocal(expr: expr, name: expr.name)
  }

  private func resolve(_ stmt: Stmt) throws {
    try stmt.accept(self)
  }

  private func resolve(_ expr: Expr) throws {
    try expr.accept(self)
  }

  private func beginScope() {
    scopes.append([:])
  }

  private func endScope() {
    assert(scopes.popLast() != nil)
  }

  private func declare(_ name: Token) {
    guard scopes.isEmpty == false else { return }
    let lastIndex = scopes.endIndex - 1
    if scopes[lastIndex][name.lexeme] != nil {
      Lox.error(token: name, message: "Already a variable with this name in this scope.")
    }
    scopes[lastIndex][name.lexeme] = false
  }

  private func define(_ name: Token) {
    guard scopes.isEmpty == false else { return }
    let lastIndex = scopes.endIndex - 1
    scopes[lastIndex][name.lexeme] = true
  }

  private func resolveLocal(expr: Expr, name: Token) throws {
    for i in scopes.indices.reversed() {
      if scopes[i][name.lexeme] != nil {
        interpreter.resolve(expr, depth: scopes.count - 1 - i)
        return
      }
    }
  }

  private func resolveFunction(_ function: Function, type: FunctionType) throws {
    let enclosingFunction = currentFunction
    currentFunction = type
    beginScope()
    for param in function.params {
      declare(param)
      define(param)
    }
    try resolve(function.body)
    endScope()
    currentFunction = enclosingFunction
  }
}