protocol LoxCallable {
  var arity: Int { get }
  func call(interpreter: Interpreter, arguments: [Object]) throws -> Object
}