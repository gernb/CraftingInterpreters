final class Scanner {
  private let source: String
  private var tokens: [Token] = []
  private var start: String.Index
  private var current: String.Index
  private var line = 1

  private static let keywords: [String: TokenType] = [
    "and": .and,
    "class": .class,
    "else": .else,
    "false": .false,
    "for": .for,
    "fun": .fun,
    "if": .if,
    "nil": .nil,
    "or": .or,
    "print": .print,
    "return": .return,
    "super": .super,
    "this": .this,
    "true": .true,
    "var": .var,
    "while": .while,
  ]

  private var isAtEnd: Bool {
    current >= source.endIndex
  }

  init(source: String) {
    self.source = source
    self.start = source.startIndex
    self.current = source.startIndex
  }

  func scanTokens() -> [Token] {
    while isAtEnd == false {
      // We are at the beginning of the next lexeme.
      start = current
      scanToken()
    }

    tokens.append(.init(type: .eof, lexeme: "", line: line))
    return tokens
  }

  private func scanToken() {
    let c = advance()
    switch c {
    case "(": addToken(.leftParen)
    case ")": addToken(.rightParen)
    case "{": addToken(.leftBrace)
    case "}": addToken(.rightBrace)
    case ",": addToken(.comma)
    case ".": addToken(.dot)
    case "-": addToken(.minus)
    case "+": addToken(.plus)
    case ";": addToken(.semicolon)
    case "*": addToken(.star)

    case "!": addToken(match("=") ? .bangEqual : .bang)
    case "=": addToken(match("=") ? .equalEqual : .equal)
    case "<": addToken(match("=") ? .lessEqual : .less)
    case ">": addToken(match("=") ? .greaterEqual: .greater)
    case "/":
      if match("/") {
        // A comment goes until the end of the line.
        while peek() != "\n" && isAtEnd == false {
          advance()
        }
      } else {
        addToken(.slash)
      }

    case " ", "\r", "\t":
      // Ignore whitespace.
      break
    case "\n":
      line += 1

    case "\"": handleString()

    default:
      if isDigit(c) {
        handleNumber()
      } else if isAlpha(c) {
        handleIdentifier()
      } else {
        Lox.error(line: line, message: "Unexpected character: '\(c)'.")
      }
    }
  }

  private func handleString() {
    while peek() != "\"" && isAtEnd == false {
      if peek() == "\n" {
        line += 1
      }
      advance()
    }

    if isAtEnd {
      Lox.error(line: line, message: "Unterminated string.")
      return
    }

    // The closing ".
    advance()

    // Trim the surrounding quotes.
    let value = String(source[start ..< current].dropFirst().dropLast())
    addToken(.string(value))
  }

  private func handleNumber() {
    while isDigit(peek()) {
      advance()
    }

    // Look for a fractional part.
    if peek() == "." && isDigit(peekNext()) {
      // Consume the "."
      advance()

      while isDigit(peek()) {
        advance()
      }
    }

    let value = Double(String(source[start ..< current]))!
    addToken(.number(value))
  }

  private func handleIdentifier() {
    while isAlphaNumeric(peek()) {
      advance()
    }

    let text = String(source[start ..< current])
    if let type = Self.keywords[text] {
      addToken(type)
    } else {
      addToken(.identifier)
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

  private func isAlphaNumeric(_ char: Character) -> Bool {
    isAlpha(char) || isDigit(char)
  }

  private func match(_ expected: Character) -> Bool {
    guard isAtEnd == false else { return false }

    if source[current] == expected {
      current = source.index(after: current)
      return true
    } else {
      return false
    }
  }

  private func peek() -> Character {
    isAtEnd ? "\0" : source[current]
  }

  private func peekNext() -> Character {
    let next = source.index(after: current)
    guard next < source.endIndex else { return "\0" }
    return source[next]
  }

  @discardableResult
  private func advance() -> Character {
    let char = source[current]
    current = source.index(after: current)
    return char
  }

  private func addToken(_ type: TokenType) {
    let text = String(source[start ..< current])
    tokens.append(.init(type: type, lexeme: text, line: line))
  }
}