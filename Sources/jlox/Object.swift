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
  var literal: Literal {
    switch self {
    case .boolean(let value): Literal(value)
    case .number(let value): Literal(value)
    case .string(let value): Literal(value)
    }
  }
}

extension Literal {
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