let DEBUG_TRACE_EXECUTION = true
let DEBUG_PRINT_CODE = true

enum Debug {
  static func disassemble(chunk: Chunk, name: String) {
    print("== \(name) ==")

    var offset = 0
    while offset < chunk.code.count {
      offset = disassembleInstruction(at: offset, in: chunk)
    }
  }

  @discardableResult
  static func disassembleInstruction(at offset: Int, in chunk: Chunk) -> Int {
    print(String(format: "%04d ", offset), terminator: "")
    if offset > 0 && chunk.lines[offset] == chunk.lines[offset - 1] {
      print("   | ", terminator: "")
    } else {
      print(String(format: "%4d ", chunk.lines[offset]), terminator: "")
    }

    let instruction = chunk.code[offset]
    let opCode = OpCode(rawValue: instruction)
    switch opCode {
    case .constant:
      return constantInstruction(opCode, chunk: chunk, offset: offset)
    case .nil:
      return simpleInstruction(opCode, offset: offset)
    case .true:
      return simpleInstruction(opCode, offset: offset)
    case .false:
      return simpleInstruction(opCode, offset: offset)
    case .equal:
      return simpleInstruction(opCode, offset: offset)
    case .greater:
      return simpleInstruction(opCode, offset: offset)
    case .less:
      return simpleInstruction(opCode, offset: offset)
    case .add:
      return simpleInstruction(opCode, offset: offset)
    case .subtract:
      return simpleInstruction(opCode, offset: offset)
    case .multiply:
      return simpleInstruction(opCode, offset: offset)
    case .divide:
      return simpleInstruction(opCode, offset: offset)
    case .negate:
      return simpleInstruction(opCode, offset: offset)
    case .not:
      return simpleInstruction(opCode, offset: offset)
    case .return:
      return simpleInstruction(opCode, offset: offset)
    case .none:
      print("Unknown opcode \(instruction)")
      return offset + 1
    }
  }

  private static func constantInstruction(_ opCode: OpCode!, chunk: Chunk, offset: Int) -> Int {
    let constant = chunk.code[offset + 1]
    print(String(format: "%-16@ %4d '", opCode.description, constant), terminator: "")
    print(chunk.constants.values[Int(constant)], terminator: "")
    print("'")
    return offset + 2
  }

  private static func simpleInstruction(_ opCode: OpCode!, offset: Int) -> Int {
    print(opCode.description)
    return offset + 1
  }
}

enum Log {
  static func trace(block: () -> Void) {
    #if DEBUG
    guard DEBUG_TRACE_EXECUTION else { return }
    block()
    #endif
  }

  static func print(block: () -> Void) {
    #if DEBUG
    guard DEBUG_PRINT_CODE else { return }
    block()
    #endif
  }
}