enum Compiler {
  nonisolated(unsafe) private static var scanner: Scanner!
  nonisolated(unsafe) private static var parser: Parser!
  nonisolated(unsafe) private static var current: Compiler!
  nonisolated(unsafe) private static var currentClass: ClassCompiler?

  private static var currentChunk: Chunk {
    get { current.function.chunk }
    set { current.function.chunk = newValue }
  }

  enum Constants {
    static let uint8Count = Int(UInt8.max) + 1
    static let initString = "init"
  }

  static func compile(_ source: String) -> ObjFunction? {
    scanner = Scanner(source)
    current = Compiler(type: .script)
    parser = Parser()

    advance()
    while match(.eof) == false {
      declaration()
    }
    let function = endCompiler()

    return parser.hadError ? nil : function
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

  private static func declaration() {
    if match(.class) {
      classDeclaration()
    } else if match(.fun) {
      funDeclaration()
    } else if match(.var) {
      varDeclaration()
    } else {
      statement()
    }

    if parser.panicMode {
      synchronize()
    }
  }

  private static func classDeclaration() {
    consume(type: .identifier, message: "Expect class name.")
    let className = parser.previous
    let nameConstant = identifierConstant(parser.previous)
    declareVariable()

    emitBytes(opCode: .class, byte: nameConstant)
    defineVariable(nameConstant)

    currentClass = ClassCompiler(currentClass)

    namedVariable(className, canAssign: false)
    consume(type: .leftBrace, message: "Expect '{' before class body.")
    while check(.rightBrace) == false && check(.eof) == false {
      method()
    }
    consume(type: .rightBrace, message: "Expect '}' after class body.")
    emitOpCode(.pop)

    currentClass = currentClass?.enclosing
  }

  private static func funDeclaration() {
    let global = parseVariable(errorMessage: "Expect function name.")
    markInitialized()
    function(type: .function)
    defineVariable(global)
  }

  private static func varDeclaration() {
    let global = parseVariable(errorMessage: "Expect variable name.")

    if match(.equal) {
      expression()
    } else {
      emitOpCode(.nil)
    }
    consume(type: .semicolon, message: "Expect ';' after variable declaration.")

    defineVariable(global)
  }

  private static func statement() {
    if match(.print) {
      printStatement()
    } else if match(.for) {
      forStatement()
    } else if match(.if) {
      ifStatement()
    } else if match(.return) {
      returnStatement()
    } else if match(.while) {
      whileStatement()
    } else if match(.leftBrace) {
      beginScope()
      block()
      endScope()
    } else {
      expressionStatement()
    }
  }

  private static func printStatement() {
    expression()
    consume(type: .semicolon, message: "Expect ';' after value.")
    emitOpCode(.print)
  }

  private static func forStatement() {
    beginScope()
    consume(type: .leftParen, message: "Expect '(' after 'for'.")
    if match(.semicolon) {
      // No initializer.
    } else if match(.var) {
      varDeclaration()
    } else {
      expressionStatement()
    }

    var loopStart = currentChunk.code.count
    var exitJump = -1
    if match(.semicolon) == false {
      expression()
      consume(type: .semicolon, message: "Expect ';' after loop condition.")

      // Jump out of the loop if the condition is false.
      exitJump = emitJump(.jumpIfFalse)
      emitOpCode(.pop) // Condition.
    }

    if match(.rightParen) == false {
      let bodyJump = emitJump(.jump)
      let incrementStart = currentChunk.code.count
      expression()
      emitOpCode(.pop)
      consume(type: .rightParen, message: "Expect ')' after for clauses.")

      emitLoop(loopStart)
      loopStart = incrementStart
      patchJump(offset: bodyJump)
    }

    statement()
    emitLoop(loopStart)

    if exitJump != -1 {
      patchJump(offset: exitJump)
      emitOpCode(.pop)  // Condition.
    }

    endScope()
  }

  private static func ifStatement() {
    consume(type: .leftParen, message: "Expect '(' after 'if'.")
    expression()
    consume(type: .rightParen, message: "Expect ')' after condition.")

    let thenJump = emitJump(.jumpIfFalse)
    emitOpCode(.pop)
    statement()
    let elseJump = emitJump(.jump)
    patchJump(offset: thenJump)
    emitOpCode(.pop)

    if match(.else) {
      statement()
    }
    patchJump(offset: elseJump)
  }

  private static func whileStatement() {
    let loopStart = currentChunk.code.count
    consume(type: .leftParen, message: "Expect '(' after 'while'.")
    expression()
    consume(type: .rightParen, message: "Expect ')' after condition.")

    let exitJump = emitJump(.jumpIfFalse)
    emitOpCode(.pop)
    statement()
    emitLoop(loopStart)

    patchJump(offset: exitJump)
    emitOpCode(.pop)
  }

  private static func returnStatement() {
    if current.type == .script {
      error(message: "Can't return from top-level code.")
    }
    if match(.semicolon) {
      emitReturn()
    } else {
      if current.type == .initializer {
        error(message: "Can't return a value from an initializer.")
      }
      expression()
      consume(type: .semicolon, message: "Expect ';' after return value.")
      emitOpCode(.return)
    }
  }

  private static func block() {
    while check(.rightBrace) == false && check(.eof) == false {
      declaration()
    }
    consume(type: .rightBrace, message: "Expect '}' after block.")
  }

  private static func expressionStatement() {
    expression()
    consume(type: .semicolon, message: "Expect ';' after expression.")
    emitOpCode(.pop)
  }

  private static func synchronize() {
    parser.panicMode = false

    while parser.current.type != .eof {
      if parser.previous.type == .semicolon {
        return
      }

      switch parser.current.type {
      case .class, .fun, .var,
            .for, .if, .while,
            .print, .return:
        return
      default:
        break // Do nothing.
      }

      advance()
    }
  }

  private static func consume(type: Scanner.TokenType, message: String) {
    if parser.current.type == type {
      advance()
      return
    }

    errorAtCurrent(message: message)
  }

  private static func match(_ type: Scanner.TokenType) -> Bool {
    guard check(type) else { return false }
    advance()
    return true
  }

  private static func check(_ type: Scanner.TokenType) -> Bool {
    parser.current.type == type
  }

  private static func function(type: FunctionType) {
    let compiler = Compiler(type: type)
    current = compiler
    beginScope()

    consume(type: .leftParen, message: "Expect '(' after function name.")
    if check(.rightParen) == false {
      repeat {
        current.function.arity += 1
        if current.function.arity > 255 {
          errorAtCurrent(message: "Can't have more than 255 parameters.")
        }
        let constant = parseVariable(errorMessage: "Expect parameter name.")
        defineVariable(constant)
      } while match(.comma)
    }
    consume(type: .rightParen, message: "Expect ')' after parameters.")
    consume(type: .leftBrace, message: "Expect '{' before function body.")
    block()

    let function = endCompiler()
    emitBytes(opCode: .closure, byte: makeConstant(.object(.function(function))))
    for i in 0 ..< function.upvalueCount {
      emitByte(compiler.upvalues[i].isLocal ? 1 : 0)
      emitByte(compiler.upvalues[i].index)
    }
  }

  private static func method() {
    consume(type: .identifier, message: "Expect method name.")
    let constant = identifierConstant(parser.previous)
    let type: FunctionType = parser.previous.lexeme == Constants.initString ? .initializer : .method
    function(type: type)
    emitBytes(opCode: .method, byte: constant)
  }

  private static func this(_: Bool) {
    guard currentClass != nil else {
      error(message: "Can't use 'this' outside of a class.")
      return
    }
    variable(canAssign: false)
  }

  private static func expression() {
    parsePrecedence(.assignment)
  }

  private static func number(_: Bool) {
    let value = Double(parser.previous.lexeme)!
    emitConstant(Value(floatLiteral: value))
  }

  private static func grouping(_: Bool) {
    expression()
    consume(type: .rightParen, message: "Expect ')' after expression.")
  }

  private static func unary(_: Bool) {
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

  private static func binary(_: Bool) {
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

  private static func call(_: Bool) {
    let argCount = argumentList()
    emitBytes(opCode: .call, byte: argCount)
  }

  private static func dot(canAssign: Bool) {
    consume(type: .identifier, message: "Expect property name after '.'.")
    let name = identifierConstant(parser.previous)

    if canAssign && match(.equal) {
      expression()
      emitBytes(opCode: .setProperty, byte: name)
    } else if match(.leftParen) {
      let argCount = argumentList()
      emitBytes(opCode: .invoke, byte: name)
      emitByte(argCount)
    } else {
      emitBytes(opCode: .getProperty, byte: name)
    }
  }

  private static func literal(_: Bool) {
    switch parser.previous.type {
      case .false: emitOpCode(.false)
      case .nil: emitOpCode(.nil)
      case .true: emitOpCode(.true)
      default: return // Unreachable.
    }
  }

  private static func string(_: Bool) {
    let value = parser.previous.lexeme.dropFirst().dropLast()
    emitConstant(Value(stringLiteral: String(value)))
  }

  private static func variable(canAssign: Bool) {
    namedVariable(parser.previous, canAssign: canAssign)
  }

  private static func namedVariable(_ name: Scanner.Token, canAssign: Bool) {
    let getOp: OpCode
    let setOp: OpCode
    var arg = resolveLocal(compiler: current, name: name)
    if arg != -1 {
      getOp = .getLocal
      setOp = .setLocal
    } else {
      arg = resolveUpvalue(compiler: current, name: name)
      if arg != -1 {
        getOp = .getUpvalue;
        setOp = .setUpvalue;
      } else {
        arg = Int(identifierConstant(name))
        getOp = .getGlobal
        setOp = .setGlobal
      }
    }
    if canAssign && match(.equal) {
      expression()
      emitBytes(opCode: setOp, byte: UInt8(arg))
    } else {
      emitBytes(opCode: getOp, byte: UInt8(arg))
    }
  }

  private static func parsePrecedence(_ precedence: Precedence) {
    advance()
    guard let prefixRule = getRule(for: parser.previous.type).prefix else {
      error(message: "Expect expression.")
      return
    }

    let canAssign = precedence <= .assignment
    prefixRule(canAssign)

    while precedence <= getRule(for: parser.current.type).precedence {
      advance()
      let infixRule = getRule(for: parser.previous.type).infix!
      infixRule(canAssign)
    }

    if canAssign && match(.equal) {
      error(message: "Invalid assignment target.")
    }
  }

  private static func parseVariable(errorMessage: String) -> UInt8 {
    consume(type: .identifier, message: errorMessage)
    declareVariable()
    if current.scopeDepth > 0 {
      return 0
    }
    return identifierConstant(parser.previous)
  }

  private static func identifierConstant(_ name: Scanner.Token) -> UInt8 {
    makeConstant(Value(stringLiteral: name.lexeme))
  }

  private static func declareVariable() {
    if current.scopeDepth == 0 {
      return
    }
    let name = parser.previous
    for local in current.locals.reversed() {
      if local.depth != -1 && local.depth < current.scopeDepth {
        break
      }
      if identifiersEqual(name, local.name) {
        error(message: "Already a variable with this name in this scope.")
      }
    }
    addLocal(name)
  }

  private static func identifiersEqual(_ a: Scanner.Token, _ b: Scanner.Token) -> Bool {
    a.lexeme == b.lexeme
  }

  private static func addLocal(_ name: Scanner.Token) {
    guard current.locals.count < Constants.uint8Count else {
      error(message: "Too many local variables in function.")
      return
    }
    let local = Local(name: name, depth: -1, isCaptured: false)
    current.locals.append(local)
  }

  private static func resolveLocal(compiler: Compiler, name: Scanner.Token) -> Int {
    for (i, local) in compiler.locals.enumerated().reversed() {
      if identifiersEqual(name, local.name) {
        if local.depth == -1 {
          error(message: "Can't read local variable in its own initializer.")
        }
        return i
      }
    }
    return -1
  }

  private static func resolveUpvalue(compiler: Compiler, name: Scanner.Token) -> Int {
    guard let enclosing = compiler.enclosing else { return -1 }

    let local = resolveLocal(compiler: enclosing, name: name)
    if local != -1 {
      compiler.enclosing.locals[local].isCaptured = true
      return addUpvalue(compiler, index: UInt8(local), isLocal: true)
    }
    let upvalue = resolveUpvalue(compiler: compiler.enclosing, name: name)
    if upvalue != -1 {
      return addUpvalue(compiler, index: UInt8(upvalue), isLocal: false)
    }

    return -1
  }

  private static func addUpvalue(_ compiler: Compiler, index: UInt8, isLocal: Bool) -> Int {
    let existing = compiler.upvalues
      .enumerated()
      .first { _, element in
        element.index == index && element.isLocal == isLocal
      }
    if let (index, _) = existing {
      return index
    }
    let upvalueCount = compiler.function.upvalueCount
    if upvalueCount == Constants.uint8Count {
      error(message: "Too many closure variables in function.")
      return 0
    }
    compiler.upvalues.append(Upvalue(index: index, isLocal: isLocal))
    compiler.function.upvalueCount += 1
    return upvalueCount
  }

  private static func defineVariable(_ global: UInt8) {
    if current.scopeDepth > 0 {
      markInitialized()
      return
    }
    emitBytes(opCode: .defineGlobal, byte: global)
  }

  private static func argumentList() -> UInt8 {
    var argCount: UInt8 = 0
    if check(.rightParen) == false {
      repeat {
        expression()
        if argCount == 255 {
          error(message: "Can't have more than 255 arguments.")
        }
        argCount += 1
      } while match(.comma)
    }
    consume(type: .rightParen, message: "Expect ')' after arguments.")
    return argCount
  }

  private static func `and`(_: Bool) {
    let endJump = emitJump(.jumpIfFalse)

    emitOpCode(.pop)
    parsePrecedence(.and)

    patchJump(offset: endJump)
  }

  private static func `or`(_: Bool) {
    let elseJump = emitJump(.jumpIfFalse)
    let endJump = emitJump(.jump)

    patchJump(offset: elseJump)
    emitOpCode(.pop)

    parsePrecedence(.or)
    patchJump(offset: endJump)
  }

  private static func markInitialized() {
    guard current.scopeDepth > 0 else { return }
    current.locals[current.locals.count - 1].depth = current.scopeDepth
  }

  private static func beginScope() {
    current.scopeDepth += 1
  }

  private static func endScope() {
    current.scopeDepth -= 1
    while let last = current.locals.last, last.depth > current.scopeDepth {
      if last.isCaptured {
        emitOpCode(.closeUpvalue)
      } else {
        emitOpCode(.pop)
      }
      _ = current.locals.popLast()
    }
  }

  private static func endCompiler() -> ObjFunction {
    emitReturn()
    let function = current.function
    Log.print {
      if parser.hadError == false {
        Debug.disassemble(
          chunk: currentChunk,
          name: function.name.isEmpty ? "<script>" : function.name
        )
      }
    }
    current = current.enclosing
    return function
  }

  private static func getRule(for type: Scanner.TokenType) -> ParseRule {
    ParseRule.rules[type]!
  }

  private static func emitConstant(_ value: Value) {
    emitBytes(opCode: .constant, byte: makeConstant(value))
  }

  private static func emitReturn() {
    if current.type == .initializer {
      emitBytes(opCode: .getLocal, byte: 0)
    } else {
      emitOpCode(.nil)
    }
    emitOpCode(.return)
  }

  private static func emitJump(_ instruction: OpCode) -> Int {
    emitOpCode(instruction)
    emitByte(0xff)
    emitByte(0xff)
    return currentChunk.code.count - 2
  }

  private static func patchJump(offset: Int) {
    // -2 to adjust for the bytecode for the jump offset itself.
    let jump = currentChunk.code.count - offset - 2

    if jump > UInt16.max {
      error(message: "Too much code to jump over.")
    }

    currentChunk.setByte(at: offset, UInt8((jump >> 8) & 0xff))
    currentChunk.setByte(at: offset + 1, UInt8(jump & 0xff))
  }

  private static func emitLoop(_ loopStart: Int) {
    emitOpCode(.loop)

    let offset = currentChunk.code.count - loopStart + 2
    if offset > UInt16.max {
      error(message: "Loop body too large.")
    }

    emitByte(UInt8((offset >> 8) & 0xff))
    emitByte(UInt8(offset & 0xff))
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
    typealias ParseFn = (Bool) -> Void
    let prefix: ParseFn?
    let infix: ParseFn?
    let precedence: Precedence

    nonisolated(unsafe) static let rules: [Scanner.TokenType: ParseRule] = [
      .leftParen: .init(prefix: grouping, infix: call, precedence: .call),
      .rightParen: .init(prefix: nil, infix: nil, precedence: .none),
      .leftBrace: .init(prefix: nil, infix: nil, precedence: .none),
      .rightBrace: .init(prefix: nil, infix: nil, precedence: .none),
      .comma: .init(prefix: nil, infix: nil, precedence: .none),
      .dot: .init(prefix: nil, infix: dot, precedence: .call),
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
      .identifier: .init(prefix: variable, infix: nil, precedence: .none),
      .string: .init(prefix: string, infix: nil, precedence: .none),
      .number: .init(prefix: number, infix: nil, precedence: .none),
      .and: .init(prefix: nil, infix: `and`, precedence: .none),
      .class: .init(prefix: nil, infix: nil, precedence: .none),
      .else: .init(prefix: nil, infix: nil, precedence: .none),
      .false: .init(prefix: literal, infix: nil, precedence: .none),
      .for: .init(prefix: nil, infix: nil, precedence: .none),
      .fun: .init(prefix: nil, infix: nil, precedence: .none),
      .if: .init(prefix: nil, infix: nil, precedence: .none),
      .nil: .init(prefix: literal, infix: nil, precedence: .none),
      .or: .init(prefix: nil, infix: `or`, precedence: .none),
      .print: .init(prefix: nil, infix: nil, precedence: .none),
      .return: .init(prefix: nil, infix: nil, precedence: .none),
      .super: .init(prefix: nil, infix: nil, precedence: .none),
      .this: .init(prefix: this, infix: nil, precedence: .none),
      .true: .init(prefix: literal, infix: nil, precedence: .none),
      .var: .init(prefix: nil, infix: nil, precedence: .none),
      .while: .init(prefix: nil, infix: nil, precedence: .none),
      .error: .init(prefix: nil, infix: nil, precedence: .none),
      .eof: .init(prefix: nil, infix: nil, precedence: .none),
    ]
  }

  final class Compiler {
    let enclosing: Compiler!
    var function: ObjFunction
    var type: FunctionType
    var locals: [Local]
    var upvalues: [Upvalue]
    var scopeDepth: Int

    init(type: FunctionType) {
      self.enclosing = current
      self.function = .init()
      self.type = type
      self.locals = []
      self.locals.reserveCapacity(Constants.uint8Count)
      self.upvalues = []
      self.upvalues.reserveCapacity(Constants.uint8Count)
      self.scopeDepth = 0
      if type != .script {
        function.name = parser.previous.lexeme
      }
      locals.append(
        .init(
          name: .init(type: .error, lexeme: type != .function ? "this" : "", line: -1),
          depth: 0,
          isCaptured: false
        )
      )
    }
  }

  final class ClassCompiler {
    let enclosing: ClassCompiler?

    init(_ enclosing: ClassCompiler? = nil) {
      self.enclosing = enclosing
    }
  }

  struct Local {
    let name: Scanner.Token
    var depth: Int
    var isCaptured: Bool
  }

  struct Upvalue {
    let index: UInt8
    let isLocal: Bool
  }

  enum FunctionType {
    case function, initializer, method, script
  }
}