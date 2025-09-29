final class LoxInstance: CustomStringConvertible {
  var description: String { "\(loxClass.name) instance" }

  private let loxClass: LoxClass
  private var fields: [String: Object] = [:]

  init(_ loxClass: LoxClass) {
    self.loxClass = loxClass
  }

  func get(_ name: Token) throws -> Object {
    if let value = fields[name.lexeme] {
      return value
    }
    if let method = loxClass.findMethod(name.lexeme) {
      return .function(method.bind(self))
    }
    throw Interpreter.RuntimeError(op: name, message: "Undefined property '\(name.lexeme)'.")
  }

  func set(_ name: Token, value: Object) {
    fields[name.lexeme] = value
  }
}