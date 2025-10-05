enum Value {
  case bool(Bool)
  case `nil`
  case number(Double)

  var asBool: Bool? {
    guard case .bool(let value) = self else { return nil }
    return value
  }
  var asNumber: Double? {
    guard case .number(let value) = self else { return nil }
    return value
  }

  var isBool: Bool {
    guard case .bool = self else { return false }
    return true
  }
  var isNil: Bool {
    guard case .nil = self else { return false }
    return true
  }
  var isNumber: Bool {
    guard case .number = self else { return false }
    return true
  }

  var type: ValueType {
    switch self {
    case .bool: .bool
    case .nil: .nil
    case .number: .number
    }
  }

  enum ValueType {
    case bool, `nil`, number
  }
}

extension Value {
  static func + (lhs: Self, rhs: Self) -> Self {
    guard let l = lhs.asNumber, let r = rhs.asNumber else {
      fatalError("Cannot use the '+' operator on non-numeric values")
    }
    return .number(l + r)
  }
  static func - (lhs: Self, rhs: Self) -> Self {
    guard let l = lhs.asNumber, let r = rhs.asNumber else {
      fatalError("Cannot use the '-' operator on non-numeric values")
    }
    return .number(l - r)
  }
  static func * (lhs: Self, rhs: Self) -> Self {
    guard let l = lhs.asNumber, let r = rhs.asNumber else {
      fatalError("Cannot use the '*' operator on non-numeric values")
    }
    return .number(l * r)
  }
  static func / (lhs: Self, rhs: Self) -> Self {
    guard let l = lhs.asNumber, let r = rhs.asNumber else {
      fatalError("Cannot use the '/' operator on non-numeric values")
    }
    return .number(l / r)
  }
  static prefix func - (_ value: Self) -> Self {
    guard let value = value.asNumber else {
      fatalError("Cannot use the negate operator on a non-numeric value")
    }
    return .number(-value)
  }
  static func == (lhs: Self, rhs: Self) -> Self {
    guard lhs.type == rhs.type else { return false }
    let value = switch (lhs.type) {
    case .bool: lhs.asBool == rhs.asBool
    case .nil: true
    case .number: lhs.asNumber == rhs.asNumber
    }
    return .bool(value)
  }
  static func > (lhs: Self, rhs: Self) -> Self {
    guard let l = lhs.asNumber, let r = rhs.asNumber else {
      fatalError("Cannot use the '>' operator on non-numeric values")
    }
    return .bool(l > r)
  }
  static func < (lhs: Self, rhs: Self) -> Self {
    guard let l = lhs.asNumber, let r = rhs.asNumber else {
      fatalError("Cannot use the '<' operator on non-numeric values")
    }
    return .bool(l < r)
  }
}

extension Value: CustomStringConvertible {
  var description: String {
    switch self {
    case .bool(let value): "\(value)"
    case .nil: "nil"
    case .number(let value): "\(value)"
    }
  }
}

extension Value: ExpressibleByBooleanLiteral {
    init(booleanLiteral value: Bool) {
      self = .bool(value)
    }
}
extension Value: ExpressibleByFloatLiteral {
    init(floatLiteral value: Double) {
      self = .number(value)
    }
}
extension Value: ExpressibleByNilLiteral {
    init(nilLiteral: ()) {
      self = .nil
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