enum Object: Equatable {
  case `nil`
  case boolean(Bool)
  case number(Double)
  case string(String)
}

extension Object: CustomStringConvertible {
  var description: String {
    switch self {
    case .nil: "nil"
    case .boolean(let value): "\(value)"
    case .number(let value): "\(value)"
    case .string(let value): "\(value)"
    }
  }
}

extension Expr.Literal {
  init(_ value: Object?) {
    self.init(value: value ?? .nil)
  }
  init(_ value: Bool) {
    self.init(value: .boolean(value))
  }
  init(_ value: Double) {
    self.init(value: .number(value))
  }
  init(_ value: String) {
    self.init(value: .string(value))
  }
}