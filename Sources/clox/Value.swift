enum Value {
  case number(Double)
}
extension Value {
  static func + (lhs: Self, rhs: Self) -> Self {
    guard case .number(let l) = lhs, case .number(let r) = rhs else {
      fatalError("Cannot use the '+' operator on non-numeric values")
    }
    return .number(l + r)
  }
  static func - (lhs: Self, rhs: Self) -> Self {
    guard case .number(let l) = lhs, case .number(let r) = rhs else {
      fatalError("Cannot use the '-' operator on non-numeric values")
    }
    return .number(l - r)
  }
  static func * (lhs: Self, rhs: Self) -> Self {
    guard case .number(let l) = lhs, case .number(let r) = rhs else {
      fatalError("Cannot use the '*' operator on non-numeric values")
    }
    return .number(l * r)
  }
  static func / (lhs: Self, rhs: Self) -> Self {
    guard case .number(let l) = lhs, case .number(let r) = rhs else {
      fatalError("Cannot use the '/' operator on non-numeric values")
    }
    return .number(l / r)
  }
  static prefix func - (_ value: Self) -> Self {
    guard case .number(let value) = value else {
      fatalError("Cannot use the negate operator on a non-numeric value")
    }
    return .number(-value)
  }
}
extension Value: CustomStringConvertible {
  var description: String {
    switch self {
    case .number(let value): "\(value)"
    }
  }
}
extension Value: ExpressibleByFloatLiteral {
    init(floatLiteral value: Double) {
      self = .number(value)
    }
}

struct ValueArray {
  private(set) var values: [Value]
  var count: Int { values.count }

  init() {
    values = []
  }

  mutating func write(value: Value) {
    if values.capacity < values.count + 1 {
      values.reserveCapacity(Memory.growCapacity(values.capacity))
    }

    values.append(value)
  }

  mutating func free() {
    values = []
  }
}