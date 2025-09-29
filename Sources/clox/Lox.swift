import Foundation

@main
struct Lox {
  static func main() {
    let vm = VM()
    var chunk = Chunk()
    var constant = chunk.addConstant(value: 1.2)
    chunk.write(opCode: .constant, line: 123)
    chunk.write(byte: constant, line: 123)

    constant = chunk.addConstant(value: 3.4)
    chunk.write(opCode: .constant, line: 123)
    chunk.write(byte: constant, line: 123)

    chunk.write(opCode: .add, line: 123)

    constant = chunk.addConstant(value: 5.6)
    chunk.write(opCode: .constant, line: 123)
    chunk.write(byte: constant, line: 123)

    chunk.write(opCode: .divide, line: 123)

    chunk.write(opCode: .negate, line: 123)
    chunk.write(opCode: .return, line: 123)
    Debug.disassemble(chunk: chunk, name: "test chunk")
    _ = vm.interpret(chunk: chunk)
    chunk.free()
  }
}
