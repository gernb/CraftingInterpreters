enum Debug {
  static func disassemble(chunk: Chunk, name: String) {
    print("== \(name) ==")

    var offset = 0
    while offset < chunk.code.count {
      offset = disassembleInstruction(at: offset, in: chunk)
    }
  }

  private static func disassembleInstruction(at offset: Int, in chunk: Chunk) -> Int {
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
      return constantInstruction(name: opCode!.description, chunk: chunk, offset: offset)
    case .return:
      return simpleInstruction(name: opCode!.description, offset: offset)
    case .none:
      print("Unknown opcode \(instruction)");
      return offset + 1
    }
  }

  private static func constantInstruction(name: String, chunk: Chunk, offset: Int) -> Int {
    let constant = chunk.code[offset + 1]
    print(String(format: "%-16@ %4d '", name, constant), terminator: "")
    print(chunk.constants.values[Int(constant)], terminator: "")
    print("'")
    return offset + 2
  }

  private static func simpleInstruction(name: String, offset: Int) -> Int {
    print(name)
    return offset + 1
  }
}