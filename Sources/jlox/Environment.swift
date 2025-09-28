final class Environment {
  private let enclosing: Environment?
  private var values: [String: Object] = [:]

  init(enclosing: Environment? = nil) {
    self.enclosing = enclosing
  }

  func get(_ name: Token) throws -> Object {
    if let value = try values[name.lexeme] ?? enclosing?.get(name) {
      return value
    }
    throw Interpreter.RuntimeError(op: name, message: "Undefined variable '\(name.lexeme)'.")
  }

  func assign(name: Token, value: Object) throws {
    if values.keys.contains(name.lexeme) {
      values[name.lexeme] = value
    } else if let enclosing {
      try enclosing.assign(name: name, value: value)
    } else {
      throw Interpreter.RuntimeError(op: name, message: "Undefined variable '\(name.lexeme)'.")
    }
  }

  func define(name: String, value: Object) {
    values[name] = value
  }
}