import Foundation

final class Interpreter: ExprVisitor, StmtVisitor {
  struct RuntimeError: Error {
    let op: Token
    let message: String
  }

  private let globals: Environment
  private var environment: Environment
  private var locals: [Expr.ID: Int]

  init() {
    let globals = Environment()
    self.globals = globals
    self.environment = globals
    self.locals = [:]

    struct Clock: LoxCallable, CustomStringConvertible {
      var description: String { "<native fn>" }
      let arity = 0
      func call(interpreter: Interpreter, arguments: [Object]) throws -> Object {
        .number(Date().timeIntervalSince1970)
      }
    }
    globals.define(name: "clock", value: .function(Clock()))
  }

  func interpret(_ statements: [Stmt]) {
    do {
      for statement in statements {
        try execute(statement)
      }
    } catch let error as RuntimeError {
      Lox.runtimeError(error)
    } catch {
      fatalError(String(describing: error))
    }
  }

  func resolve(_ expr: Expr, depth: Int) {
    locals[expr.id] = depth
  }

  func visitAssignExpr(_ expr: Assign) throws -> Object {
    let value = try evaluate(expr.value)
    let distance = locals[expr.id]
    if let distance {
      environment.assignAt(distance, name: expr.name, value: value)
    } else {
      try globals.assign(name: expr.name, value: value)
    }
    return value
  }

  func visitBinaryExpr(_ expr: Binary) throws -> Object {
    let left = try evaluate(expr.left)
    let right = try evaluate(expr.right)

    switch expr.operator.type {
    case .bangEqual:
      return .boolean(left != right)
    case .equalEqual:
      return .boolean(left == right)
    case .greater:
      let lval = try getNumberOperand(op: expr.operator, operand: left)
      let rval = try getNumberOperand(op: expr.operator, operand: right)
      return .boolean(lval > rval)
    case .greaterEqual:
      let lval = try getNumberOperand(op: expr.operator, operand: left)
      let rval = try getNumberOperand(op: expr.operator, operand: right)
      return .boolean(lval >= rval)
    case .less:
      let lval = try getNumberOperand(op: expr.operator, operand: left)
      let rval = try getNumberOperand(op: expr.operator, operand: right)
      return .boolean(lval < rval)
    case .lessEqual:
      let lval = try getNumberOperand(op: expr.operator, operand: left)
      let rval = try getNumberOperand(op: expr.operator, operand: right)
      return .boolean(lval <= rval)
    case .minus:
      let lval = try getNumberOperand(op: expr.operator, operand: left)
      let rval = try getNumberOperand(op: expr.operator, operand: right)
      return .number(lval - rval)
    case .plus:
      if case .number(let lval) = left, case .number(let rval) = right {
        return .number(lval + rval)
      }
      if case .string(let lval) = left, case .string(let rval) = right {
        return .string(lval + rval)
      }
      throw RuntimeError(op: expr.operator, message: "Operands must be two numbers or two strings.")
    case .slash:
      let lval = try getNumberOperand(op: expr.operator, operand: left)
      let rval = try getNumberOperand(op: expr.operator, operand: right)
      return .number(lval / rval)
    case .star:
      let lval = try getNumberOperand(op: expr.operator, operand: left)
      let rval = try getNumberOperand(op: expr.operator, operand: right)
      return .number(lval * rval)
    default:
      fatalError("Unsupported binary operator: \(expr.operator)")
    }
  }

  func visitCallExpr(_ expr: Call) throws -> Object {
    let callee = try evaluate(expr.callee)
    let arguments = try expr.arguments.map(evaluate(_:))
    guard case .function(let loxFunction) = callee else {
      throw RuntimeError(op: expr.paren, message: "Can only call functions and classes.")
    }
    guard arguments.count == loxFunction.arity else {
      throw RuntimeError(op: expr.paren, message: "Expected \(loxFunction.arity) arguments but got \(arguments.count).")
    }
    return try loxFunction.call(interpreter: self, arguments: arguments)
  }

  func visitGetExpr(_ expr: Get) throws -> Object {
    let object = try evaluate(expr.object)
    if case .instance(let instance) = object {
      return try instance.get(expr.name)
    }
    throw RuntimeError(op: expr.name, message: "Only instances have properties.")
  }

  func visitGroupingExpr(_ expr: Grouping) throws -> Object {
    try evaluate(expr.expression)
  }

  func visitLiteralExpr(_ expr: Literal) throws -> Object {
    expr.value
  }

  func visitLogicalExpr(_ expr: Logical) throws -> Object {
    let left = try evaluate(expr.left)

    if expr.operator.type == .or {
      if isTruthy(left) {
        return left
      }
    } else {
      if isTruthy(left) == false {
        return left
      }
    }

    return try evaluate(expr.right)
  }

  func visitSetExpr(_ expr: Set) throws -> Object {
    let object = try evaluate(expr.object)
    guard case .instance(let instance) = object else {
      throw RuntimeError(op: expr.name, message: "Only instances have fields.")
    }
    let value = try evaluate(expr.value)
    instance.set(expr.name, value: value)
    return value
  }

  func visitSuperExpr(_ expr: Super) throws -> Object {
    guard let distance = locals[expr.id],
      case .function(let loxFunc) = try environment.getAt(distance, name: "super"),
      let superclass = loxFunc as? LoxClass,
      case .instance(let this) = try environment.getAt(distance - 1, name: "this"),
      let method = superclass.findMethod(expr.method.lexeme)
    else {
      throw RuntimeError(op: expr.method, message: "Undefined property '\(expr.method.lexeme)'.")
    }
    return .function(method.bind(this))
  }

  func visitThisExpr(_ expr: This) throws -> Object {
    try lookUpVariable(name: expr.keyword, expr: expr)
  }

  func visitUnaryExpr(_ expr: Unary) throws -> Object {
    let right = try evaluate(expr.right)

    switch expr.operator.type {
    case .bang:
      return .boolean(!isTruthy(right))
    case .minus:
      let value = try getNumberOperand(op: expr.operator, operand: right)
      return .number(-value)
    default:
      fatalError("Unsupported unary operator: \(expr.operator)")
    }
  }

  func visitVariableExpr(_ expr: Variable) throws -> Object {
    try lookUpVariable(name: expr.name, expr: expr)
  }

  func visitBlockStmt(_ stmt: Block) throws {
    try executeBlock(stmt.statements, environment: .init(enclosing: environment))
  }

  func visitClassStmt(_ stmt: Class) throws {
    let superclass: LoxClass?
    if let superclassVar = stmt.superclass {
      let object = try evaluate(superclassVar)
      guard case .function(let loxFunc) = object, let loxClass = loxFunc as? LoxClass else {
        throw RuntimeError(op: superclassVar.name, message: "Superclass must be a class.")
      }
      superclass = loxClass
    } else {
      superclass = nil
    }

    environment.define(name: stmt.name.lexeme, value: .nil)

    if let superclass {
      environment = Environment(enclosing: environment)
      environment.define(name: "super", value: .function(superclass))
    }

    var methods: [String: LoxFunction] = [:]
    for method in stmt.methods {
      let function = LoxFunction(
        method,
        closure: environment,
        isInitializer: method.name.lexeme == "init"
      )
      methods[method.name.lexeme] = function
    }

    let loxClass = LoxClass(name: stmt.name.lexeme, superclass: superclass, methods: methods)

    if superclass != nil {
      environment = environment.enclosing!
    }

    try environment.assign(name: stmt.name, value: .function(loxClass))
  }

  func visitExpressionStmt(_ stmt: Expression) throws {
    try evaluate(stmt.expression)
  }

  func visitFunctionStmt(_ stmt: Function) throws {
    let function = LoxFunction(stmt, closure: environment, isInitializer: false)
    environment.define(name: stmt.name.lexeme, value: .function(function))
  }

  func visitIfStmt(_ stmt: If) throws {
    if isTruthy(try evaluate(stmt.condition)) {
      try execute(stmt.thenBranch)
    } else if let elseBranch = stmt.elseBranch {
      try execute(elseBranch)
    }
  }

  func visitPrintStmt(_ stmt: Print) throws {
    let value = try evaluate(stmt.expression)
    print(stringify(value))
  }

  func visitReturnStmt(_ stmt: Return) throws {
    let value = try stmt.value.map(evaluate(_:)) ?? .nil
    throw ReturnException(value: value)
  }

  func visitVarStmt(_ stmt: Var) throws {
    let value = if let initializer = stmt.initializer {
      try evaluate(initializer)
    } else {
      Object.nil
    }
    environment.define(name: stmt.name.lexeme, value: value)
  }

  func visitWhileStmt(_ stmt: While) throws {
    while isTruthy(try evaluate(stmt.condition)) {
      try execute(stmt.body)
    }
  }

  @discardableResult
  private func evaluate(_ expr: Expr) throws -> Object {
    try expr.accept(self)
  }

  private func execute(_ stmt: Stmt) throws {
    try stmt.accept(self)
  }

  func executeBlock(_ statements: [Stmt], environment: Environment) throws {
    let previous = self.environment
    defer {
      self.environment = previous
    }
    self.environment = environment
    for statement in statements {
      try execute(statement)
    }
  }

  private func isTruthy(_ object: Object) -> Bool {
    switch object {
    case .nil, .boolean(false): false
    default: true
    }
  }

  private func getNumberOperand(op: Token, operand: Object) throws -> Double {
    guard case .number(let value) = operand else {
      throw RuntimeError(op: op, message: "Operand must be a number.")
    }
    return value
  }

  private func lookUpVariable(name: Token, expr: Expr) throws -> Object {
    let distance = locals[expr.id]
    if let distance {
      return try environment.getAt(distance, name: name.lexeme)
    } else {
      return try globals.get(name)
    }
  }

  private func stringify(_ object: Object) -> String {
    let text = object.description
    if case .number = object, text.hasSuffix(".0") {
      return String(text.dropLast(2))
    }
    return text
  }
}