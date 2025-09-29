enum Value {
  case number(Double)
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