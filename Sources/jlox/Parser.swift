/*
program        → declaration* EOF ;

declaration    → varDecl
               | statement ;

varDecl        → "var" IDENTIFIER ( "=" expression )? ";" ;

statement      → exprStmt
               | ifStmt
               | printStmt
               | block ;
exprStmt       → expression ";" ;
ifStmt         → "if" "(" expression ")" statement
               ( "else" statement )? ;
printStmt      → "print" expression ";" ;
block          → "{" declaration* "}" ;

expression     → assignment ;
assignment     → IDENTIFIER "=" assignment
               | logic_or ;
logic_or       → logic_and ( "or" logic_and )* ;
logic_and      → equality ( "and" equality )* ;
equality       → comparison ( ( "!=" | "==" ) comparison )* ;
comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
term           → factor ( ( "-" | "+" ) factor )* ;
factor         → unary ( ( "/" | "*" ) unary )* ;
unary          → ( "!" | "-" ) unary
               | primary ;
primary        → "true" | "false" | "nil"
               | NUMBER | STRING
               | "(" expression ")"
               | IDENTIFIER ;
*/

final class Parser {
  private struct ParseError: Error {}

  private let tokens: [Token]
  private var current = 0

  init(tokens: [Token]) {
    self.tokens = tokens
  }

  func parse() -> [Stmt] {
    var statements: [Stmt] = []
    while isAtEnd() == false {
      guard let statement = declaration() else { continue }
      statements.append(statement)
    }
    return statements
  }

  private func declaration() -> Stmt? {
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

  private func varDeclaration() throws -> Stmt {
    let name = try consume(.identifier, message: "Expect variable name.")
    let initializer = match(.equal) ? try expression() : nil
    try consume(.semicolon, message: "Expect ';' after variable declaration.")
    return Var(name: name, initializer: initializer)
  }

  private func statement() throws -> Stmt {
    if match(.if) {
      return try ifStatement()
    }
    if match(.print) {
      return try printStatement()
    }
    if match(.leftBrace) {
      return try Block(statements: block())
    }
    return try expressionStatement()
  }

  private func ifStatement() throws -> Stmt {
    try consume(.leftParen, message: "Expect '(' after 'if'.")
    let condition = try expression()
    try consume(.rightParen, message: "Expect ')' after if condition.")
    let thenBranch = try statement()
    let elseBranch = match(.else) ? try statement() : nil
    return If(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)
  }

  private func printStatement() throws -> Stmt {
    let value = try expression()
    try consume(.semicolon, message: "Expect ';' after value.")
    return Print(expression: value)
  }

  private func block() throws -> [Stmt] {
    var statements: [Stmt] = []
    while check(.rightBrace) == false && isAtEnd() == false {
      guard let statement = declaration() else { continue }
      statements.append(statement)
    }
    try consume(.rightBrace, message: "Expect '}' after block.")
    return statements
  }

  private func expressionStatement() throws -> Stmt {
    let expr = try expression()
    try consume(.semicolon, message: "Expect ';' after expression.")
    return Expression(expression: expr)
  }

  private func expression() throws -> Expr {
    try assignment()
  }

  private func assignment() throws -> Expr {
    let expr = try or()

    if match(.equal) {
      let equals = previous()
      let value = try assignment()

      if let variable = expr as? Variable {
        let name = variable.name
        return Assign(name: name, value: value)
      }

      error(token: equals, message: "Invalid assignment target.")
    }

    return expr
  }

  private func or() throws -> Expr {
    var expr = try and()

    while match(.or) {
      let op = previous()
      let right = try and()
      expr = Logical(left: expr, operator: op, right: right)
    }

    return expr
  }

  private func and() throws -> Expr {
    var expr = try equality()

    while match(.and) {
      let op = previous()
      let right = try equality()
      expr = Logical(left: expr, operator: op, right: right)
    }

    return expr
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
      return Literal(false)
    }
    if match(.true) {
      return Literal(true)
    }
    if match(.nil) {
      return Literal(.nil)
    }

    if match(.number(0), .string("")) {
      return Literal(previous().type.value)
    }

    if match(.identifier) {
      return Variable(name: previous())
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

  @discardableResult
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