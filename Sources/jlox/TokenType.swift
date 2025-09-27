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
  case identifier(String), string(String), number(Double)

  // Keywords.
  case and, `class`, `else`, `false`, fun, `for`, `if`, `nil`, or
  case print, `return`, `super`, this, `true`, `var`, `while`

  case eof

  var literal: Any? {
    switch self {
    case .identifier(let value): value
    case .string(let value): value
    case .number(let value): value
    default: nil
    }
  }

  func sameType(as other: Self) -> Bool {
    switch (self, other) {
    case (.identifier, .identifier): true
    case (.string, .string): true
    case (.number, .number): true
    default: self == other
    }
  }
}