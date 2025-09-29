enum OpCode: UInt8 {
  case constant
  case add
  case subtract
  case multiply
  case divide
  case negate
  case `return`
}

extension OpCode: CustomStringConvertible {
  var description: String {
    switch self {
    case .constant: "OP_CONSTANT"
    case .add: "OP_ADD"
    case .subtract: "OP_SUBTRACT"
    case .multiply: "OP_MULTIPLY"
    case .divide: "OP_DIVIDE"
    case .negate: "OP_NEGATE"
    case .return: "OP_RETURN"
    }
  }
}