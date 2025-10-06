enum OpCode: UInt8 {
  case constant
  case `nil`
  case `true`
  case `false`
  case pop
  case setLocal
  case getLocal
  case defineGlobal
  case setGlobal
  case getGlobal
  case equal
  case greater
  case less
  case add
  case subtract
  case multiply
  case divide
  case not
  case negate
  case print
  case `return`
}

extension OpCode: CustomStringConvertible {
  var description: String {
    switch self {
    case .constant: "OP_CONSTANT"
    case .nil: "OP_NIL"
    case .true: "OP_TRUE"
    case .false: "OP_FALSE"
    case .pop: "OP_POP"
    case .setLocal: "OP_SET_LOCAL"
    case .getLocal: "OP_GET_LOCAL"
    case .defineGlobal: "OP_DEFINE_GLOBAL"
    case .setGlobal: "OP_SET_GLOBAL"
    case .getGlobal: "OP_GET_GLOBAL"
    case .equal: "OP_EQUAL"
    case .greater: "OP_GREATER"
    case .less: "OP_LESS"
    case .add: "OP_ADD"
    case .subtract: "OP_SUBTRACT"
    case .multiply: "OP_MULTIPLY"
    case .divide: "OP_DIVIDE"
    case .not: "OP_NOT"
    case .negate: "OP_NEGATE"
    case .print: "OP_PRINT"
    case .return: "OP_RETURN"
    }
  }
}