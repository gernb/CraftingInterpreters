final class Environment {
  private var values: [String: Object] = [:]

  func get(_ name: Token) throws -> Object {
    guard let value = values[name.lexeme] else {
      throw Interpreter.RuntimeError(op: name, message: "Undefined variable '\(name.lexeme)'.")
    }
    return value
  }

  func assign(name: Token, value: Object) throws {
    guard values.keys.contains(name.lexeme) else {
      throw Interpreter.RuntimeError(op: name, message: "Undefined variable '\(name.lexeme)'.")
    }
    values[name.lexeme] = value
  }

  func define(name: String, value: Object) {
    values[name] = value
  }
}