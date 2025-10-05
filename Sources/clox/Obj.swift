enum Obj {
  case string(String)

  var isString: Bool { type == .string }

  var asString: String? {
    guard case .string(let value) = self else { return nil }
    return value
  }

  var type: ObjType {
    switch self {
    case .string: .string
    }
  }

  enum ObjType {
    case string
  }
}

extension Obj {
  static func == (lhs: Self, rhs: Self) -> Bool {
    guard lhs.type == rhs.type else { return false }
    return switch (lhs.type) {
    case .string: lhs.asString == rhs.asString
    }
  }
}

extension Obj: CustomStringConvertible {
  var description: String {
    switch self {
    case .string(let value): value
    }
  }
}

extension Obj: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
   self = .string(value)
  }
}