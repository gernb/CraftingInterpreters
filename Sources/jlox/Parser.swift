/*
program        → declaration* EOF ;

declaration    → varDecl
               | statement ;

varDecl        → "var" IDENTIFIER ( "=" expression )? ";" ;

statement      → exprStmt
               | printStmt ;
exprStmt       → expression ";" ;
printStmt      → "print" expression ";" ;

expression     → equality ;
equality       → comparison ( ( "!=" | "==" ) comparison )* ;
comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
term           → factor ( ( "-" | "+" ) factor )* ;
factor         → unary ( ( "/" | "*" ) unary )* ;
unary          → ( "!" | "-" ) unary
               | primary ;
primary        → "true" | "false" | "nil"
               | NUMBER | STRING
               | "(" expression ")"
               | IDENTIFIER ;*/

final class Parser {
  private struct ParseError: Error {}

  private let tokens: [Token]
  private var current = 0

  init(tokens: [Token]) {
    self.tokens = tokens
  }

  func parse() -> [Stmt.Stmt] {
    var statements: [Stmt.Stmt] = []
    while isAtEnd() == false {
      guard let statement = declaration() else { continue }
      statements.append(statement)
    }
    return statements
  }

  private func declaration() -> Stmt.Stmt? {
    do {
      if match(.var) {
        return try varDeclaration()
      }
      return try statement()
    } catch {
      synchronize()
      return nil
    }
  }

  private func varDeclaration() throws -> Stmt.Stmt {
    let name = try consume(.identifier, message: "Expect variable name.")
    let initializer = match(.equal) ? try expression() : nil
    try consume(.semicolon, message: "Expect ';' after variable declaration.")
    return Stmt.Var(name: name, initializer: initializer)
  }

  private func statement() throws -> Stmt.Stmt {
    if match(.print) {
      return try printStatement()
    }
    return try expressionStatement()
  }

  private func printStatement() throws -> Stmt.Stmt {
    let value = try expression()
    try consume(.semicolon, message: "Expect ';' after value.")
    return Stmt.Print(expression: value)
  }

  private func expressionStatement() throws -> Stmt.Stmt {
    let expr = try expression()
    try consume(.semicolon, message: "Expect ';' after expression.")
    return Stmt.Expression(expression: expr)
  }

  private func expression() throws -> Expr.Expr {
    try equality()
  }

  private func equality() throws -> Expr.Expr {
    try binaryLeftAssociative(expression: comparison, matching: .bangEqual, .equalEqual)
  }

  private func comparison() throws -> Expr.Expr {
    try binaryLeftAssociative(expression: term, matching: .greater, .greaterEqual, .less, .lessEqual)
  }

  private func term() throws -> Expr.Expr {
    try binaryLeftAssociative(expression: factor, matching: .minus, .plus)
  }

  private func factor() throws -> Expr.Expr {
    try binaryLeftAssociative(expression: unary, matching: .slash, .star)
  }

  private func unary() throws -> Expr.Expr {
    if match(.bang, .minus) {
      let op = previous()
      let right = try unary()
      return Expr.Unary(operator: op, right: right)
    }

    return try primary()
  }

  private func primary() throws -> Expr.Expr {
    if match(.false) {
      return Expr.Literal(false)
    }
    if match(.true) {
      return Expr.Literal(true)
    }
    if match(.nil) {
      return Expr.Literal(.nil)
    }

    if match(.number(0), .string("")) {
      return Expr.Literal(previous().type.value)
    }

    if match(.identifier) {
      return Expr.Variable(name: previous())
    }

    if match(.leftParen) {
      let expr = try expression()
      try consume(.rightParen, message: "Expect ')' after expression.")
      return Expr.Grouping(expression: expr)
    }

    throw error(token: peek(), message: "Expect expression.")
  }

  private func binaryLeftAssociative(expression: () throws -> Expr.Expr, matching types: TokenType...) rethrows -> Expr.Expr {
    var expr = try expression()

    while match(types) {
      let op = previous()
      let right = try expression()
      expr = Expr.Binary(left: expr, operator: op, right: right)
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