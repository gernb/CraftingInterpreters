struct Token {
  let type: TokenType
  let lexeme: String
  let line: Int

  init(type: TokenType, lexeme: String, line: Int) {
    self.type = type
    self.lexeme = lexeme
    self.line = line
  }
}

extension Token: CustomStringConvertible {
  var description: String {
    "\(type) '\(lexeme)'"
  }
}