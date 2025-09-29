enum OpCode: UInt8 {
  case constant
  case `return`
}

extension OpCode: CustomStringConvertible {
  var description: String {
    switch self {
    case .constant: "OP_CONSTANT"
    case .return: "OP_RETURN"
    }
  }
}