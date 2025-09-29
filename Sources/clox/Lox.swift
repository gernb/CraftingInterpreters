import Foundation

@main
struct Lox {
  static func main() {
    var chunk = Chunk()
    let constant = chunk.addConstant(value: 1.2)
    chunk.write(opCode: .constant, line: 123)
    chunk.write(byte: UInt8(constant), line: 123) // !!!
    chunk.write(opCode: .return, line: 123)
    Debug.disassemble(chunk: chunk, name: "test chunk")
    chunk.free()
  }
}
