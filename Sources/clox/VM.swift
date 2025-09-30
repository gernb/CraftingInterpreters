final class VM {
  private var chunk: Chunk?
  private var ip: Int
  private var stack: [Value?]
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
    Compiler.compile(source)
    return .ok
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
    func binaryOp(_ op: (Value, Value) -> Value) {
      let b = pop()
      let a = pop()
      push(op(a, b))
    }

    while true {
      Log.trace {
        print("          ", terminator: "")
        for i in 0 ..< stackTop {
          print("[ \(stack[i]!) ]", terminator: "")
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

      case .add: binaryOp(+)
      case .subtract: binaryOp(-)
      case .multiply: binaryOp(*)
      case .divide: binaryOp(/)
      case .negate: push(-pop())

      case .return:
        print(pop())
        return .ok

      case .none:
        fatalError()
      }
    }
  }

  private func push(_ value: Value) {
    stack[stackTop] = value
    stackTop += 1
  }

  private func pop() -> Value {
    stackTop -= 1
    return stack[stackTop]!
  }

  private func resetStack() {
    stackTop = 0
  }
}

extension VM {
  enum InterpretResult {
    case ok, compileError, runtimeError
  }
}