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
    case .constant, .defineGlobal, .setGlobal, .getGlobal:
      return constantInstruction(opCode, chunk: chunk, offset: offset)
    case .nil,
      .true,
      .false,
      .pop,
      .equal,
      .greater,
      .less,
      .add,
      .subtract,
      .multiply,
      .divide,
      .negate,
      .not,
      .print,
      .return:
      return simpleInstruction(opCode, offset: offset)
    case .setLocal, .getLocal:
      return byteInstruction(opCode, chunk: chunk, offset: offset)
    case .jump, .jumpIfFalse:
      return jumpInstruction(opCode, sign: 1, chunk: chunk, offset: offset)
    case .loop:
      return jumpInstruction(opCode, sign: -1, chunk: chunk, offset: offset)
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

  private static func byteInstruction(_ opCode: OpCode!, chunk: Chunk, offset: Int) -> Int {
    let slot = chunk.code[offset + 1]
    print(String(format: "%-16@ %4d", opCode.description, slot))
    return offset + 2
  }

  private static func jumpInstruction(_ opCode: OpCode!, sign: Int, chunk: Chunk, offset: Int) -> Int {
    var jump = Int(chunk.code[offset + 1]) << 8
    jump |= Int(chunk.code[offset + 2])
    print(String(format: "%-16@ %4d -> %d", opCode.description, offset, offset + 3 + sign * jump))
    return offset + 3
  }

  private static func simpleInstruction(_ opCode: OpCode!, offset: Int) -> Int {
    print(opCode.description)
    return offset + 1
  }
}

enum Log {
  static func trace(block: () -> Void) {
    #if TraceExecution
    block()
    #endif
  }

  static func print(block: () -> Void) {
    #if PrintCode
    block()
    #endif
  }
}