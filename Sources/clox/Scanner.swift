final class Scanner {
  private let source: String
  private var start: String.Index
  private var current: String.Index
  private var line: Int

  private var isAtEnd: Bool {
    current == source.endIndex
  }

  init(_ source: String) {
    self.source = source
    self.start = source.startIndex
    self.current = source.startIndex
    self.line = 1
  }

  func scanToken() -> Token {
    skipWhitespace()
    start = current

    if isAtEnd {
      return makeToken(.eof)
    }

    let c = advance()
    if isAlpha(c) {
      return identifier()
    }
    if isDigit(c) {
      return number()
    }

    switch c {
    case "(": return makeToken(.leftParen)
    case ")": return makeToken(.rightParen)
    case "{": return makeToken(.leftBrace)
    case "}": return makeToken(.rightBrace)
    case ";": return makeToken(.semicolon)
    case ",": return makeToken(.comma)
    case ".": return makeToken(.dot)
    case "-": return makeToken(.minus)
    case "+": return makeToken(.plus)
    case "/": return makeToken(.slash)
    case "*": return makeToken(.star)
    case "!": return makeToken(
      match("=") ? .bangEqual : .bang
    )
    case "=": return makeToken(
      match("=") ? .equalEqual : .equal
    )
    case "<": return makeToken(
      match("=") ? .lessEqual : .less
    )
    case ">": return makeToken(
      match("=") ? .greaterEqual : .greater
    )
    case "\"": return string()
    default: return Token.errorToken("Unexpected character.", at: line)
    }
  }

  private func makeToken(_ type: TokenType) -> Token {
    Token(type: type, lexeme: String(source[start..<current]), line: line)
  }

  private func string() -> Token {
    while peek() != "\"" && isAtEnd == false {
      if peek() == "\n" {
        line += 1
      }
      advance()
    }

    if isAtEnd {
      return Token.errorToken("Unterminated string.", at: line)
    }

    // The closing quote.
    advance()
    return makeToken(.string)
  }

  private func number() -> Token {
    while isDigit(peek()) {
      advance()
    }

    // Look for a fractional part.
    if peek() == "." && isDigit(peekNext()) {
      // Consume the ".".
      advance()

      while isDigit(peek()) {
        advance()
      }
    }

    return makeToken(.number)
  }

  private func identifier() -> Token {
    while isAlpha(peek()) || isDigit(peek()) {
      advance()
    }
    return makeToken(identifierType())
  }

  private func skipWhitespace() {
    while true {
      let c = peek()
      switch c {
      case " ", "\r", "\t":
        advance()
      case "\n":
        line += 1
        advance()
      case "/":
        if peekNext() == "/" {
          // A comment goes until the end of the line.
          while peek() != "\n" && isAtEnd == false {
            advance()
          }
        } else {
          return
        }
      default:
        return
      }
    }
  }

  private func isDigit(_ char: Character) -> Bool {
    switch char {
    case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9": true
    default: false
    }
  }

  private func isAlpha(_ char: Character) -> Bool {
    char.isLetter || char == "_"
  }

  private func peek() -> Character {
    guard isAtEnd == false else { return "\0" }
    return source[current]
  }

  private func peekNext() -> Character {
    guard isAtEnd == false else { return "\0" }
    return source[source.index(after: current)]
  }

  @discardableResult
  private func advance() -> Character {
    defer { current = source.index(after: current) }
    return source[current]
  }

  private func match(_ expected: Character) -> Bool {
    guard isAtEnd == false else { return false }
    if source[current] == expected {
      advance()
      return true
    } else {
      return false
    }
  }

  private func identifierType() -> TokenType {
    switch source[start] {
    case "a": return checkKeyword(1, 2, "nd", .and)
    case "c": return checkKeyword(1, 4, "lass", .class)
    case "e": return checkKeyword(1, 3, "lse", .else)
    case "f":
      if source[start ..< current].count > 1 {
        switch source[source.index(after: start)] {
        case "a": return checkKeyword(2, 3, "lse", .false)
        case "o": return checkKeyword(2, 1, "r", .for)
        case "u": return checkKeyword(2, 1, "n", .fun)
        default: break
        }
      }
    case "i": return checkKeyword(1, 1, "f", .if)
    case "n": return checkKeyword(1, 2, "il", .nil)
    case "o": return checkKeyword(1, 1, "r", .or)
    case "p": return checkKeyword(1, 4, "rint", .print)
    case "r": return checkKeyword(1, 5, "eturn", .return)
    case "s": return checkKeyword(1, 4, "uper", .super)
    case "t":
      if source[start ..< current].count > 1 {
        switch source[source.index(after: start)] {
        case "h": return checkKeyword(2, 2, "is", .this)
        case "r": return checkKeyword(2, 2, "ue", .true)
        default: break
        }
      }
    case "v": return checkKeyword(1, 2, "ar", .var)
    case "w": return checkKeyword(1, 4, "hile", .while)
    default: break
    }
    return .identifier
  }

  private func checkKeyword(_ start: Int, _ length: Int, _ rest: String, _ type: TokenType) -> TokenType {
    let lexeme = source[self.start ..< current]
    let startIdx = source.index(self.start, offsetBy: start)
    let endIdx = source.index(self.start, offsetBy: start + length)
    let match = source[startIdx ..< endIdx]

    if lexeme.count == start + length && match == rest {
      return type
    }
    return .identifier
  }
}

extension Scanner {
  struct Token {
    let type: TokenType
    let lexeme: String
    let line: Int

    static func errorToken(_ message: String, at line: Int) -> Token {
      Token(type: .error, lexeme: message, line: line)
    }
  }

  enum TokenType: UInt8 {
    // Single-character tokens.
    case leftParen, rightParen
    case leftBrace, rightBrace
    case comma, dot, minus, plus
    case semicolon, slash, star

    // One or two character tokens.
    case bang, bangEqual
    case equal, equalEqual
    case greater, greaterEqual
    case less, lessEqual

    // Literals.
    case identifier, string, number

    // Keywords.
    case and, `class`, `else`, `false`
    case `for`, fun, `if`, `nil`, or
    case print, `return`, `super`, this
    case `true`, `var`, `while`

    case error, eof
  }
}