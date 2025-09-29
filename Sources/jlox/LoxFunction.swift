final class LoxFunction: LoxCallable, CustomStringConvertible {
  var description: String { "<fn \(declaration.name.lexeme)>" }
  var arity: Int { declaration.params.count }

  private let declaration: Function
  private let closure: Environment
  private let isInitializer: Bool

  init(_ declaration: Function, closure: Environment, isInitializer: Bool) {
    self.declaration = declaration
    self.closure = closure
    self.isInitializer = isInitializer
  }

  func call(interpreter: Interpreter, arguments: [Object]) throws -> Object {
    let environment = Environment(enclosing: closure)
    for (index, param) in declaration.params.enumerated() {
      environment.define(name: param.lexeme, value: arguments[index])
    }

    do {
      try interpreter.executeBlock(declaration.body, environment: environment)
    } catch let returnValue as ReturnException {
      return isInitializer ? try closure.getAt(0, name: "this") : returnValue.value
    }

    return isInitializer ? try closure.getAt(0, name: "this") : .nil
  }

  func bind(_ instance: LoxInstance) -> LoxFunction {
    let environment = Environment(enclosing: closure)
    environment.define(name: "this", value: .instance(instance))
    return LoxFunction(declaration, closure: environment, isInitializer: isInitializer)
  }
}