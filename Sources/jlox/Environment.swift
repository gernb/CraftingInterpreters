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

  func getAt(_ distance: Int, name: String) throws -> Object {
    guard let value = ancestor(distance).values[name] else {
      fatalError("Tight-coupling between the Resolver and the Interpreter should prevent this from ever happening.")
    }
    return value
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

  func assignAt(_ distance: Int, name: Token, value: Object) {
    ancestor(distance).values[name.lexeme] = value
  }

  func define(name: String, value: Object) {
    values[name] = value
  }

  private func ancestor(_ distance: Int) -> Environment {
    var environment = self
    for _ in 0 ..< distance {
      environment = environment.enclosing!
    }
    return environment
  }
}