enum Object {
  case `nil`
  case boolean(Bool)
  case number(Double)
  case string(String)
  case function(LoxCallable)
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
    }
  }
}

extension Literal {
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