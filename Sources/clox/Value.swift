enum Value {
  case bool(Bool)
  case `nil`
  case number(Double)
  case object(Obj)

  var asBool: Bool? {
    guard case .bool(let value) = self else { return nil }
    return value
  }
  var asNumber: Double? {
    guard case .number(let value) = self else { return nil }
    return value
  }
  var asString: String? {
    self.asObject?.asString
  }
  var asObject: Obj? {
    guard case .object(let value) = self else { return nil }
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
  var isString: Bool {
    guard case .object(let value) = self else { return false }
    return value.isString
  }
  var isObject: Bool {
    guard case .object = self else { return false }
    return true
  }

  var type: ValueType {
    switch self {
    case .bool: .bool
    case .nil: .nil
    case .number: .number
    case .object: .object
    }
  }

  enum ValueType {
    case bool, `nil`, number, object
  }
}

extension Value {
  static func + (lhs: Self, rhs: Self) throws -> Self {
    if let l = lhs.asNumber, let r = rhs.asNumber {
      return .number(l + r)
    } else if let l = lhs.asString, let r = rhs.asString {
      return .init(stringLiteral: l + r)
    } else {
      throw VM.RuntimeError(message: "Operands must be two numbers or two strings.")
    }
  }
  static func - (lhs: Self, rhs: Self) throws -> Self {
    guard let l = lhs.asNumber, let r = rhs.asNumber else {
      throw VM.RuntimeError(message: "Operands must be numbers.")
    }
    return .number(l - r)
  }
  static func * (lhs: Self, rhs: Self) throws -> Self {
    guard let l = lhs.asNumber, let r = rhs.asNumber else {
      throw VM.RuntimeError(message: "Operands must be numbers.")
    }
    return .number(l * r)
  }
  static func / (lhs: Self, rhs: Self) throws -> Self {
    guard let l = lhs.asNumber, let r = rhs.asNumber else {
      throw VM.RuntimeError(message: "Operands must be numbers.")
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
    case .object: lhs.asObject! == rhs.asObject!
    }
    return .bool(value)
  }
  static func > (lhs: Self, rhs: Self) throws -> Self {
    guard let l = lhs.asNumber, let r = rhs.asNumber else {
      throw VM.RuntimeError(message: "Operands must be numbers.")
    }
    return .bool(l > r)
  }
  static func < (lhs: Self, rhs: Self) throws -> Self {
    guard let l = lhs.asNumber, let r = rhs.asNumber else {
      throw VM.RuntimeError(message: "Operands must be numbers.")
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
    case .object(let value): "\(value.description)"
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
extension Value: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
    self.init(obj: Obj(stringLiteral: value))
  }
}
extension Value {
  init(obj value: Obj) {
    self = .object(value)
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