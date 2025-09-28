enum TokenType: Equatable {
  // Single-character tokens.
  case leftParen, rightParen, leftBrace, rightBrace
  case comma, dot, minus, plus, semicolon, slash, star

  // One or two character tokens.
  case bang, bangEqual
  case equal, equalEqual
  case greater, greaterEqual
  case less, lessEqual

  // Literals.
  case identifier, string(String), number(Double)

  // Keywords.
  case and, `class`, `else`, `false`, fun, `for`, `if`, `nil`, or
  case print, `return`, `super`, this, `true`, `var`, `while`

  case eof

  var value: Object? {
    switch self {
    case .string(let value): .string(value)
    case .number(let value): .number(value)
    case .nil: .nil
    default: nil
    }
  }

  func sameType(as other: Self) -> Bool {
    switch (self, other) {
    case (.string, .string): true
    case (.number, .number): true
    default: self == other
    }
  }
}