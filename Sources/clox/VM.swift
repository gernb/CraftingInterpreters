final class VM {
  private var chunk: Chunk?
  private var ip: Int
  private var stack: [Value]
  private var stackTop: Int

  private enum Constants {
    static let stackMax = 256
  }

  init() {
    self.ip = 0
    self.stack = Array(repeating: nil, count: Constants.stackMax)
    self.stackTop = 0
  }

  deinit {
  }

  @discardableResult
  func interpret(_ source: String) -> InterpretResult {
    guard let chunk = Compiler.compile(source) else {
      return .compileError
    }

    self.chunk = chunk
    self.ip = 0

    let result = run()
    return result
  }

  private func run() -> InterpretResult {
    guard let chunk else {
      fatalError()
    }

    func readByte() -> UInt8 {
      defer { ip += 1 }
      return chunk.code[ip]
    }
    func readConstant() -> Value {
      chunk.constants.values[Int(readByte())]
    }
    func binaryOp(_ op: (Value, Value) throws -> Value) throws {
      let b = pop()
      let a = pop()
      try push(op(a, b))
    }

    do {
      while true {
        Log.trace {
          print("          ", terminator: "")
          for i in 0 ..< stackTop {
            print("[ \(stack[i]) ]", terminator: "")
          }
          print("")
          Debug.disassembleInstruction(at: ip, in: chunk)
        }

        let instruction = readByte()
        let opCode = OpCode(rawValue: instruction)
        switch opCode {
        case .constant:
          let constant = readConstant()
          push(constant)
        case .nil: push(nil)
        case .true: push(true)
        case .false: push(false)
        case .equal:
          let b = pop()
          let a = pop()
          push(a == b)
        case .greater: try binaryOp(>)
        case .less: try binaryOp(<)
        case .add: try binaryOp(+)
        case .subtract: try binaryOp(-)
        case .multiply: try binaryOp(*)
        case .divide: try binaryOp(/)
        case .not: push(Value(booleanLiteral: isFalsey(pop())))
        case .negate:
          guard peek(0).isNumber else {
            runtimeError("Operand must be a number.")
            return .runtimeError
          }
          push(-pop())

        case .return:
          print(pop())
          return .ok

        case .none:
          fatalError()
        }
      }
    } catch let error as RuntimeError {
      runtimeError(error.message)
      return .runtimeError
    } catch {
      fatalError()
    }
  }

  private func push(_ value: Value) {
    stack[stackTop] = value
    stackTop += 1
  }

  private func pop() -> Value {
    stackTop -= 1
    return stack[stackTop]
  }

  private func peek(_ distance: Int) -> Value {
    stack[stackTop - 1 - distance]
  }

  private func isFalsey(_ value: Value) -> Bool {
    value.isNil || (value.isBool && !value.asBool!)
  }

  private func resetStack() {
    stackTop = 0
  }

  private func runtimeError(_ message: String) {
    print(message)
    let instruction = ip - 1
    let line = chunk!.lines[instruction]
    print("[line \(line)] in script")
    resetStack()
  }
}

extension VM {
  enum InterpretResult {
    case ok, compileError, runtimeError
  }

  struct RuntimeError: Swift.Error {
    let message: String
  }
}