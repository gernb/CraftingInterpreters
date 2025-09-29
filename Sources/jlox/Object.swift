enum Object {
  case `nil`
  case boolean(Bool)
  case number(Double)
  case string(String)
  case function(LoxCallable)
  case instance(LoxInstance)
}
extension Object: Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.nil, .nil): true
    case let (.boolean(l), .boolean(r)): l == r
    case let (.number(l), .number(r)): l == r
    case let (.string(l), .string(r)): l == r
    default: false
    }
  }
}

extension Object: CustomStringConvertible {
  var description: String {
    switch self {
    case .nil: "nil"
    case .boolean(let value): "\(value)"
    case .number(let value): "\(value)"
    case .string(let value): "\(value)"
    case .function(let value): "\(value)"
    case .instance(let value): "\(value)"
    }
  }
}

extension Literal {
  init(_ value: Object?, id: Int) {
    self.init(id: id, value: value ?? .nil)
  }
  init(_ value: Bool, id: Int) {
    self.init(id: id, value: .boolean(value))
  }
  init(_ value: Double, id: Int) {
    self.init(id: id, value: .number(value))
  }
  init(_ value: String, id: Int) {
    self.init(id: id, value: .string(value))
  }
}