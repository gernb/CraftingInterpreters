struct AstPrinter: Visitor {
  func print(expr: Expr) -> String {
    try! expr.accept(self)
  }

  func visitBinaryExpr(_ expr: Binary) -> String {
    parenthesize(name: expr.operator.lexeme, exprs: expr.left, expr.right)
  }

  func visitGroupingExpr(_ expr: Grouping) -> String {
    parenthesize(name: "group", exprs: expr.expression)
  }

  func visitLiteralExpr(_ expr: Literal) -> String {
    "\(expr.value, default: "nil")"
  }

  func visitUnaryExpr(_ expr: Unary) -> String {
    parenthesize(name: expr.operator.lexeme, exprs: expr.right)
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
      left: Unary(
        operator: Token(type: .minus, lexeme: "-", line: 1),
        right: Literal(123)
      ),
      operator: Token(type: .star, lexeme: "*", line: 1),
      right: Grouping(
        expression: Literal(45.67)
      )
    )
    Swift.print(AstPrinter().print(expr: expression))
  }
}
