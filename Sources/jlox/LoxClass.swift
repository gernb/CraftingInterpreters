final class LoxClass: LoxCallable, CustomStringConvertible {
  var description: String { name }
  var arity: Int {
    findMethod("init")?.arity ?? 0
  }
  let name: String
  let methods: [String: LoxFunction]

  init(name: String, methods: [String: LoxFunction]) {
    self.name = name
    self.methods = methods
  }

  func call(interpreter: Interpreter, arguments: [Object]) throws -> Object {
    let instance = LoxInstance(self)
    if let initializer = findMethod("init") {
      // ignore the return value from invoking "init" here
      _ = try initializer.bind(instance).call(interpreter: interpreter, arguments: arguments)
    }
    return .instance(instance)
  }

  func findMethod(_ name: String) -> LoxFunction? {
    methods[name]
  }
}