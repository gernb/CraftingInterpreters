struct AstPrinter: ExprVisitor {
  func print(expr: Expr) -> String {
    try! expr.accept(self)
  }

  func visitAssignExpr(_ expr: Assign) throws -> String {
    parenthesize(name: expr.name.lexeme, exprs: expr.value)
  }

  func visitBinaryExpr(_ expr: Binary) -> String {
    parenthesize(name: expr.operator.lexeme, exprs: expr.left, expr.right)
  }

  func visitCallExpr(_ expr: Call) throws -> String {
    parenthesize(name: "call", exprs: expr.callee)
  }

  func visitGroupingExpr(_ expr: Grouping) -> String {
    parenthesize(name: "group", exprs: expr.expression)
  }

  func visitLiteralExpr(_ expr: Literal) -> String {
    "\(expr.value, default: "nil")"
  }

  func visitLogicalExpr(_ expr: Logical) throws -> String {
    parenthesize(name: expr.operator.lexeme, exprs: expr.left, expr.right)
  }

  func visitUnaryExpr(_ expr: Unary) -> String {
    parenthesize(name: expr.operator.lexeme, exprs: expr.right)
  }

  func visitVariableExpr(_ expr: Variable) -> String {
    "(var \(expr.name.lexeme))"
  }

  private func parenthesize(name: String, exprs: Expr...) -> String {
    var result = "("
    result.append(name)
    for expr in exprs {
      result.append(" ")
      try! result.append(expr.accept(self))
    }
    result.append(")")

    return result
  }
}

extension AstPrinter {
  static func test() {
    let expression: Expr = Binary(
      id: 0,
      left: Unary(
        id: 1,
        operator: Token(type: .minus, lexeme: "-", line: 1),
        right: Literal(123, id: 2)
      ),
      operator: Token(type: .star, lexeme: "*", line: 1),
      right: Grouping(
        id: 3,
        expression: Literal(45.67, id: 4)
      )
    )
    Swift.print(AstPrinter().print(expr: expression))
  }
}
