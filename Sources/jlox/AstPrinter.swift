struct AstPrinter: Expr.Visitor {
  func print(expr: Expr.Expr) -> String {
    try! expr.accept(self)
  }

  func visitBinaryExpr(_ expr: Expr.Binary) -> String {
    parenthesize(name: expr.operator.lexeme, exprs: expr.left, expr.right)
  }

  func visitGroupingExpr(_ expr: Expr.Grouping) -> String {
    parenthesize(name: "group", exprs: expr.expression)
  }

  func visitLiteralExpr(_ expr: Expr.Literal) -> String {
    "\(expr.value, default: "nil")"
  }

  func visitUnaryExpr(_ expr: Expr.Unary) -> String {
    parenthesize(name: expr.operator.lexeme, exprs: expr.right)
  }

  private func parenthesize(name: String, exprs: Expr.Expr...) -> String {
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
    let expression: Expr.Expr = Expr.Binary(
      left: Expr.Unary(
        operator: Token(type: .minus, lexeme: "-", line: 1),
        right: Expr.Literal(123)
      ),
      operator: Token(type: .star, lexeme: "*", line: 1),
      right: Expr.Grouping(
        expression: Expr.Literal(45.67)
      )
    )
    Swift.print(AstPrinter().print(expr: expression))
  }
}
