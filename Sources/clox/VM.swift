import Foundation

final class VM {
  private var frames: [CallFrame]
  private var stack: [Value]
  private var stackTop: Int
  private var globals: [String: Value]

  private enum Constants {
    static let framesMax = 64
    static let stackMax = framesMax * Compiler.Constants.uint8Count
  }

  init() {
    self.frames = []
    self.frames.reserveCapacity(Constants.framesMax)
    self.stack = Array(repeating: nil, count: Constants.stackMax)
    self.stackTop = 0
    self.globals = [:]

    defineNative(
      name: "clock",
      function: { _, _ in
        .number(Date().timeIntervalSince1970)
      }
    )
  }

  deinit {
  }

  @discardableResult
  func interpret(_ source: String) -> InterpretResult {
    guard let function = Compiler.compile(source) else {
      return .compileError
    }

    push(.object(.function(function)))
    call(function, 0)

    let result = run()
    return result
  }

  private func run() -> InterpretResult {
    var frame = frames.last!

    func readByte() -> UInt8 {
      defer { frame.ip += 1 }
      return frame.function.chunk.code[frame.ip]
    }
    func readShort() -> Int {
      let msb = Int(readByte()) << 8
      let lsb = Int(readByte())
      return msb | lsb
    }
    func readConstant() -> Value {
      frame.function.chunk.constants.values[Int(readByte())]
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
          Debug.disassembleInstruction(at: frame.ip, in: frame.function.chunk)
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
        case .pop: _ = pop()
        case .setLocal:
          let slot = Int(readByte())
          stack[frame.slots + slot] = peek(0) 
        case .getLocal:
          let slot = Int(readByte())
          push(stack[frame.slots + slot])
        case .defineGlobal:
          let name = readConstant().asString!
          globals[name] = peek(0)
          _ = pop()
        case .setGlobal:
          let name = readConstant().asString!
          guard globals[name] != nil else {
            runtimeError("Undefined variable '\(name)'.")
            return .runtimeError
          }
          globals[name] = peek(0)
        case .getGlobal:
          let name = readConstant().asString!
          guard let value = globals[name] else {
            runtimeError("Undefined variable '\(name)'.")
            return .runtimeError
          }
          push(value)
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
        case .print:
          print(pop())
        case .jump:
          let offset = readShort()
          frame.ip += offset
        case .jumpIfFalse:
          let offset = readShort()
          if isFalsey(peek(0)) {
            frame.ip += offset
          }
        case .loop:
          let offset = readShort()
          frame.ip -= offset
        case .call:
          let argCount = readByte()
          if callValue(peek(Int(argCount)), argCount) == false {
            return .runtimeError
          }
          frame = frames.last!
        case .return:
          let result = pop()
          _ = frames.popLast()
          if frames.isEmpty {
            _ = pop()
            return .ok
          }
          stackTop = frame.slots
          push(result)
          frame = frames.last!

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

  private func callValue(_ value: Value, _ argCount: UInt8) -> Bool {
    if let callee = value.asObject {
      switch callee {
      case .function(let function):
        return call(function, argCount)
      case .native(let native):
        let function = native.function
        let result = function(argCount, stackTop - Int(argCount))
        stackTop -= Int(argCount) + 1
        push(result)
        return true
      default:
        break // Non-callable object type.
      }
    }
    runtimeError("Can only call functions and classes.")
    return false
  }

  @discardableResult
  private func call(_ function: ObjFunction, _ argCount: UInt8) -> Bool {
    let argCount = Int(argCount)
    if argCount != function.arity {
      runtimeError("Expected \(function.arity) arguments but got \(argCount).")
      return false
    }
    if frames.count == Constants.framesMax {
      runtimeError("Stack overflow.")
      return false
    }
    frames.append(
      CallFrame(function: function, slots: stackTop - argCount - 1)
    )
    return true
  }

  private func defineNative(name: String, function: @escaping ObjNative.NativeFn) {
    globals[name] = Value(obj: .native(.init(function: function)))
  }

  private func isFalsey(_ value: Value) -> Bool {
    value.isNil || (value.isBool && !value.asBool!)
  }

  private func resetStack() {
    stackTop = 0
  }

  private func runtimeError(_ message: String) {
    print(message)

    for frame in frames.reversed() {
      let function = frame.function
      let instruction = frame.ip - 1
      let name = function.name.isEmpty ? "script" : function.name
      print("[line \(function.chunk.lines[instruction])] in \(name)")
    }

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

  final class CallFrame {
    let function: ObjFunction
    var ip: Int
    let slots: Int

    init(function: ObjFunction, slots: Int) {
      self.function = function
      self.ip = 0
      self.slots = slots
    }
  }
}