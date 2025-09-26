enum TokenType {
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
}