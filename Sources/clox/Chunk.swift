struct Chunk {
  private(set) var code: [UInt8]
  private(set) var lines: [Int]
  private(set) var constants: ValueArray

  init() {
    self.code = []
    self.lines = []
    self.constants = .init()
  }

  mutating func write(opCode: OpCode, line: Int) {
    write(byte: opCode.rawValue, line: line)
  }

  mutating func write(byte: UInt8, line: Int) {
    if code.capacity < code.count + 1 {
      code.reserveCapacity(Memory.growCapacity(code.capacity))
      lines.reserveCapacity(Memory.growCapacity(lines.capacity))
    }

    code.append(byte)
    lines.append(line)
  }

  mutating func setByte(at offset: Int, _ value: UInt8) {
    code[offset] = value
  }

  mutating func addConstant(value: Value) -> Int {
    constants.write(value: value)
    return constants.count - 1
  }

  mutating func free() {
    self.code = []
    self.lines = []
    self.constants.free()
  }
}