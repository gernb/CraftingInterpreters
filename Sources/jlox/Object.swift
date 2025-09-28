enum Object: Equatable {
  case boolean(Bool)
  case number(Double)
  case string(String)
}

extension Object: CustomStringConvertible {
  var description: String {
    switch self {
    case .boolean(let value): "\(value)"
    case .number(let value): "\(value)"
    case .string(let value): "\(value)"
    }
  }
}

extension Object {
  var literal: Expr.Literal {
    switch self {
    case .boolean(let value): Expr.Literal(value)
    case .number(let value): Expr.Literal(value)
    case .string(let value): Expr.Literal(value)
    }
  }
}

extension Expr.Literal {
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