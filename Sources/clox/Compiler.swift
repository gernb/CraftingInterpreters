enum Compiler {
  nonisolated(unsafe) private static var scanner: Scanner!
  nonisolated(unsafe) private static var parser: Parser!
  nonisolated(unsafe) private static var currentChunk: Chunk!

  static func compile(_ source: String) -> Chunk? {
    scanner = Scanner(source)
    currentChunk = Chunk()
    parser = Parser()
    advance()
    expression()
    consume(type: .eof, message: "Expect end of expression.")
    endCompiler()
    return parser.hadError ? nil : currentChunk
  }

  private static func advance() {
    parser.previous = parser.current

    while true {
      parser.current = scanner.scanToken()
      guard parser.current.type == .error else {
        break
      }

      errorAtCurrent(message: parser.current.lexeme)
    }
  }

  private static func consume(type: Scanner.TokenType, message: String) {
    if parser.current.type == type {
      advance()
      return
    }

    errorAtCurrent(message: message)
  }

  private static func expression() {
    parsePrecedence(.assignment)
  }

  private static func number() {
    let value = Double(parser.previous.lexeme)!
    emitConstant(Value(floatLiteral: value))
  }

  private static func grouping() {
    expression()
    consume(type: .rightParen, message: "Expect ')' after expression.")
  }

  private static func unary() {
    let operatorType = parser.previous.type
    // Compile the operand.
    parsePrecedence(.unary)
    // Emit the operator instruction.
    switch operatorType {
    case .bang: emitOpCode(.not)
    case .minus: emitOpCode(.negate)
    default: return // Unreachable.
    }
  }

  private static func binary() {
    let operatorType = parser.previous.type
    let rule = getRule(for: operatorType)
    parsePrecedence(rule.precedence)

    switch operatorType {
    case .bangEqual: emitBytes(opCode: .equal, byte: OpCode.not.rawValue)
    case .equalEqual: emitOpCode(.equal)
    case .greater: emitOpCode(.greater)
    case .greaterEqual: emitBytes(opCode: .less, byte: OpCode.not.rawValue)
    case .less: emitOpCode(.less)
    case .lessEqual: emitBytes(opCode: .greater, byte: OpCode.not.rawValue)
    case .plus: emitOpCode(.add)
    case .minus: emitOpCode(.subtract)
    case .star: emitOpCode(.multiply)
    case .slash: emitOpCode(.divide)
    default: return // Unreachable.
    }
  }

  private static func literal() {
    switch parser.previous.type {
      case .false: emitOpCode(.false)
      case .nil: emitOpCode(.nil)
      case .true: emitOpCode(.true)
      default: return // Unreachable.
    }
  }

  private static func parsePrecedence(_ precedence: Precedence) {
    advance()
    guard let prefixRule = getRule(for: parser.previous.type).prefix else {
      error(message: "Expect expression.")
      return
    }

    prefixRule()

    while precedence <= getRule(for: parser.current.type).precedence {
      advance()
      let infixRule = getRule(for: parser.previous.type).infix!
      infixRule()
    }
  }

  private static func endCompiler() {
    emitReturn()
    Log.print {
      if parser.hadError == false {
        Debug.disassemble(chunk: currentChunk, name: "code")
      }
    }
  }

  private static func getRule(for type: Scanner.TokenType) -> ParseRule {
    ParseRule.rules[type]!
  }

  private static func emitConstant(_ value: Value) {
    emitBytes(opCode: .constant, byte: makeConstant(value))
  }

  private static func emitReturn() {
    emitOpCode(.return)
  }

  private static func emitBytes(opCode: OpCode, byte: UInt8) {
    emitOpCode(opCode)
    emitByte(byte)
  }

  private static func emitOpCode(_ opCode: OpCode) {
    emitByte(opCode.rawValue)
  }

  private static func emitByte(_ byte: UInt8) {
    currentChunk.write(byte: byte, line: parser.previous.line)
  }

  private static func makeConstant(_ value: Value) -> UInt8 {
    let constant = currentChunk.addConstant(value: value)
    guard constant <= UInt8.max else {
      error(message: "Too many constants in one chunk.")
      return 0
    }
    return UInt8(constant)
  }

  private static func errorAtCurrent(message: String) {
    errorAt(token: parser.current, message: message)
  }

  private static func error(message: String) {
    errorAt(token: parser.previous, message: message)
  }

  private static func errorAt(token: Scanner.Token, message: String) {
    guard parser.panicMode == false else { return }
    parser.panicMode = true
    print("[line \(token.line)]", terminator: "")

    if token.type == .eof {
      print(" at end", terminator: "")
    } else if token.type == .error {
      // Nothing.
    } else {
      print(" at '\(token.lexeme)'", terminator: "")
    }

    print(": \(message)")
    parser.hadError = true
  }
}

extension Compiler {
  struct Parser {
    var current: Scanner.Token = .errorToken("Uninitialised", at: -1)
    var previous: Scanner.Token = .errorToken("Uninitialised", at: -1)
    var hadError: Bool = false
    var panicMode: Bool = false
  }

  enum Precedence: Comparable {
    case none
    case assignment  // =
    case or          // or
    case and         // and
    case equality    // == !=
    case comparison  // < > <= >=
    case term        // + -
    case factor      // * /
    case unary       // ! -
    case call        // . ()
    case primary

    var oneHigher: Precedence {
      switch self {
      case .none: .assignment
      case .assignment: .or
      case .or: .and
      case .and: .equality
      case .equality: .comparison
      case .comparison: .term
      case .term: .factor
      case .factor: .unary
      case .unary: .call
      case .call: .primary
      case .primary: .primary // ??
      }
    }
  }

  struct ParseRule {
    typealias ParseFn = () -> Void
    let prefix: ParseFn?
    let infix: ParseFn?
    let precedence: Precedence

    nonisolated(unsafe) static let rules: [Scanner.TokenType: ParseRule] = [
      .leftParen: .init(prefix: grouping, infix: nil, precedence: .none),
      .rightParen: .init(prefix: nil, infix: nil, precedence: .none),
      .leftBrace: .init(prefix: nil, infix: nil, precedence: .none),
      .rightBrace: .init(prefix: nil, infix: nil, precedence: .none),
      .comma: .init(prefix: nil, infix: nil, precedence: .none),
      .dot: .init(prefix: nil, infix: nil, precedence: .none),
      .minus: .init(prefix: unary, infix: binary, precedence: .term),
      .plus: .init(prefix: nil, infix: binary, precedence: .term),
      .semicolon: .init(prefix: nil, infix: nil, precedence: .none),
      .slash: .init(prefix: nil, infix: binary, precedence: .factor),
      .star: .init(prefix: nil, infix: binary, precedence: .factor),
      .bang: .init(prefix: unary, infix: nil, precedence: .none),
      .bangEqual: .init(prefix: nil, infix: binary, precedence: .equality),
      .equal: .init(prefix: nil, infix: nil, precedence: .none),
      .equalEqual: .init(prefix: nil, infix: binary, precedence: .equality),
      .greater: .init(prefix: nil, infix: binary, precedence: .comparison),
      .greaterEqual: .init(prefix: nil, infix: binary, precedence: .comparison),
      .less: .init(prefix: nil, infix: binary, precedence: .comparison),
      .lessEqual: .init(prefix: nil, infix: binary, precedence: .comparison),
      .identifier: .init(prefix: nil, infix: nil, precedence: .none),
      .string: .init(prefix: nil, infix: nil, precedence: .none),
      .number: .init(prefix: number, infix: nil, precedence: .none),
      .and: .init(prefix: nil, infix: nil, precedence: .none),
      .class: .init(prefix: nil, infix: nil, precedence: .none),
      .else: .init(prefix: nil, infix: nil, precedence: .none),
      .false: .init(prefix: literal, infix: nil, precedence: .none),
      .for: .init(prefix: nil, infix: nil, precedence: .none),
      .fun: .init(prefix: nil, infix: nil, precedence: .none),
      .if: .init(prefix: nil, infix: nil, precedence: .none),
      .nil: .init(prefix: literal, infix: nil, precedence: .none),
      .or: .init(prefix: nil, infix: nil, precedence: .none),
      .print: .init(prefix: nil, infix: nil, precedence: .none),
      .return: .init(prefix: nil, infix: nil, precedence: .none),
      .super: .init(prefix: nil, infix: nil, precedence: .none),
      .this: .init(prefix: nil, infix: nil, precedence: .none),
      .true: .init(prefix: literal, infix: nil, precedence: .none),
      .var: .init(prefix: nil, infix: nil, precedence: .none),
      .while: .init(prefix: nil, infix: nil, precedence: .none),
      .error: .init(prefix: nil, infix: nil, precedence: .none),
      .eof: .init(prefix: nil, infix: nil, precedence: .none),
    ]
  }
}