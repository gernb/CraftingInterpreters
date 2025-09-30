enum Compiler {
  nonisolated(unsafe) private static var scanner: Scanner!

  static func compile(_ source: String) {
    scanner = Scanner(source)

    var line = -1
    while true {
      let token = scanner.scanToken()
      if token.line != line {
        print(String(format: "%4d ", token.line), terminator: "")
        line = token.line
      } else {
        print("   | ", terminator: "")
      }
      print(String(format: "%2d '%@'", token.type.rawValue, token.lexeme))

      if token.type == .eof {
        break
      }
    }
  }
}