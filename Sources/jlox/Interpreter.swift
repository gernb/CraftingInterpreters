final class Interpreter: Visitor {
  struct RuntimeError: Error {
    let op: Token
    let message: String
  }

  func interpret(expression: Expr) { 
    do {
      let value = try evaluate(expression)
      print(stringify(value))
    } catch let error as RuntimeError {
      Lox.runtimeError(error)
    } catch {
      fatalError(String(describing: error))
    }
  }

  func visitBinaryExpr(_ expr: Binary) throws -> Object? {
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

  func visitGroupingExpr(_ expr: Grouping) throws -> Object? {
    try evaluate(expr.expression)
  }

  func visitLiteralExpr(_ expr: Literal) throws -> Object? {
    expr.value
  }

  func visitUnaryExpr(_ expr: Unary) throws -> Object? {
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

  private func evaluate(_ expr: Expr) throws -> Object? {
    try expr.accept(self)
  }

  private func isTruthy(_ object: Object?) -> Bool {
    switch object {
    case .none, .boolean(false): false
    default: true
    }
  }

  private func getNumberOperand(op: Token, operand: Object?) throws -> Double {
    guard case .number(let value) = operand else {
      throw RuntimeError(op: op, message: "Operand must be a number.")
    }
    return value
  }

  private func stringify(_ object: Object?) -> String {
    guard let object else {
      return "nil"
    }
    let text = object.description
    if case .number = object, text.hasSuffix(".0") {
      return String(text.dropLast(2))
    }
    return text
  }
}