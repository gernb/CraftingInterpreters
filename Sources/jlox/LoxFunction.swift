final class LoxFunction: LoxCallable, CustomStringConvertible {
  var description: String { "<fn \(declaration.name.lexeme)>" }
  var arity: Int { declaration.params.count }

  private let declaration: Function
  private let closure: Environment

  init(_ declaration: Function, closure: Environment) {
    self.declaration = declaration
    self.closure = closure
  }

  func call(interpreter: Interpreter, arguments: [Object]) throws -> Object {
    let environment = Environment(enclosing: closure)
    for (index, param) in declaration.params.enumerated() {
      environment.define(name: param.lexeme, value: arguments[index])
    }

    do {
      try interpreter.executeBlock(declaration.body, environment: environment)
    } catch let returnValue as ReturnException {
      return returnValue.value
    }
    return .nil
  }
}