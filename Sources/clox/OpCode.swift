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
  case setUpvalue
  case getUpvalue
  case setProperty
  case getProperty
  case getSuper
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
  case jump
  case jumpIfFalse
  case loop
  case call
  case invoke
  case superInvoke
  case closure
  case closeUpvalue
  case `return`
  case `class`
  case inherit
  case method
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
    case .setUpvalue: "OP_SET_UPVALUE"
    case .getUpvalue: "OP_GET_UPVALUE"
    case .setProperty: "OP_SET_PROPERTY"
    case .getProperty: "OP_GET_PROPERTY"
    case .getSuper: "OP_GET_SUPER"
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
    case .jump: "OP_JUMP"
    case .jumpIfFalse: "OP_JUMP_IF_FALSE"
    case .loop: "OP_LOOP"
    case .call: "OP_CALL"
    case .invoke: "OP_INVOKE"
    case .superInvoke: "OP_SUPER_INVOKE"
    case .closure: "OP_CLOSURE"
    case .closeUpvalue: "OP_CLOSE_UPVALUE"
    case .return: "OP_RETURN"
    case .class: "OP_CLASS"
    case .inherit: "OP_INHERIT"
    case .method: "OP_METHOD"
    }
  }
}