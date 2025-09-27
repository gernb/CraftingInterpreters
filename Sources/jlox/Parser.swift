/*
expression     → equality ;
equality       → comparison ( ( "!=" | "==" ) comparison )* ;
comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
term           → factor ( ( "-" | "+" ) factor )* ;
factor         → unary ( ( "/" | "*" ) unary )* ;
unary          → ( "!" | "-" ) unary
               | primary ;
primary        → NUMBER | STRING | "true" | "false" | "nil"
               | "(" expression ")" ;
*/

final class Parser {
  private struct ParseError: Error {}

  private let tokens: [Token]
  private var current = 0

  init(tokens: [Token]) {
    self.tokens = tokens
  }

  func parse() -> Expr? {
    do {
      return try expression()
    } catch {
      return nil
    }
  }

  private func expression() throws -> Expr {
    try equality()
  }

  private func equality() throws -> Expr {
    try binaryLeftAssociative(expression: comparison, matching: .bangEqual, .equalEqual)
  }

  private func comparison() throws -> Expr {
    try binaryLeftAssociative(expression: term, matching: .greater, .greaterEqual, .less, .lessEqual)
  }

  private func term() throws -> Expr {
    try binaryLeftAssociative(expression: factor, matching: .minus, .plus)
  }

  private func factor() throws -> Expr {
    try binaryLeftAssociative(expression: unary, matching: .slash, .star)
  }

  private func unary() throws -> Expr {
    if match(.bang, .minus) {
      let op = previous()
      let right = try unary()
      return Unary(operator: op, right: right)
    }

    return try primary()
  }

  private func primary() throws -> Expr {
    if match(.false) {
      return Literal(value: false)
    }
    if match(.true) {
      return Literal(value: true)
    }
    if match(.nil) {
      return Literal(value: nil)
    }

    if match(.number(0), .string("")) {
      return Literal(value: previous().type.literal)
    }

    if match(.leftParen) {
      let expr = try expression()
      try consume(.rightParen, message: "Expect ')' after expression.")
      return Grouping(expression: expr)
    }

    throw error(token: peek(), message: "Expect expression.")
  }

  private func binaryLeftAssociative(expression: () throws -> Expr, matching types: TokenType...) rethrows -> Expr {
    var expr = try expression()

    while match(types) {
      let op = previous()
      let right = try expression()
      expr = Binary(left: expr, operator: op, right: right)
    }

    return expr
  }

  private func match(_ types: TokenType...) -> Bool {
    match(types)
  }
  private func match(_ types: [TokenType]) -> Bool {
    for type in types {
      if check(type) {
        advance()
        return true
      }
    }

    return false
  }

  @discardableResult
  private func consume(_ type: TokenType, message: String) throws -> Token {
    if check(type) {
      return advance()
    }

    throw error(token: peek(), message: message)
  }

  private func check(_ type: TokenType) -> Bool {
    isAtEnd() ? false : peek().type.sameType(as: type)
  }

  @discardableResult
  private func advance() -> Token {
    if isAtEnd() == false {
      current += 1
    }
    return previous()
  }

  private func isAtEnd() -> Bool {
    peek().type == .eof
  }

  private func peek() -> Token {
    tokens[current]
  }

  private func previous() -> Token {
    tokens[current - 1]
  }

  private func error(token: Token, message: String) -> ParseError {
    Lox.error(token: token, message: message)
    return ParseError()
  }

  private func synchronize() {
    advance()

    while isAtEnd() == false {
      guard previous().type != .semicolon else { return }

      switch peek().type {
      case .class, .fun, .var, .for, .if, .while, .print, .return:
        return
      default:
        break
      }

      advance()
    }
  }
}