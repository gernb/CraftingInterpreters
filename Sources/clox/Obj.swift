enum Obj {
  case closure(ObjClosure)
  case function(ObjFunction)
  case native(ObjNative)
  case string(String)
  case upvalue(ObjUpvalue)

  var isClosure: Bool { type == .closure }
  var isFunction: Bool { type == .function }
  var isNative: Bool { type == .native }
  var isString: Bool { type == .string }

  var asClosure: ObjClosure? {
    guard case .closure(let value) = self else { return nil }
    return value
  }
  var asFunction: ObjFunction? {
    guard case .function(let value) = self else { return nil }
    return value
  }
  var asNative: ObjNative.NativeFn? {
    guard case .native(let value) = self else { return nil }
    return value.function
  }
  var asString: String? {
    guard case .string(let value) = self else { return nil }
    return value
  }

  var type: ObjType {
    switch self {
    case .closure: .closure
    case .function: .function
    case .native: .native
    case .string: .string
    case .upvalue: .upvalue
    }
  }

  enum ObjType {
    case closure, function, native, string, upvalue
  }
}

extension Obj {
  static func == (lhs: Self, rhs: Self) -> Bool {
    guard lhs.type == rhs.type else { return false }
    return switch (lhs.type) {
    case .closure, .function, .native, .upvalue: false
    case .string: lhs.asString == rhs.asString
    }
  }
}

extension Obj: CustomStringConvertible {
  var description: String {
    switch self {
    case .closure(let value): value.function.name.isEmpty ? "<script>" : "<fn \(value.function.name)>"
    case .function(let value): value.name.isEmpty ? "<script>" : "<fn \(value.name)>"
    case .native: "<native fn>"
    case .string(let value): value
    case .upvalue: "upvalue"
    }
  }
}

extension Obj: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
   self = .string(value)
  }
}

final class ObjFunction {
  var arity: Int
  var upvalueCount: Int
  var chunk: Chunk
  var name: String

  init() {
    self.arity = 0
    self.upvalueCount = 0
    self.chunk = Chunk()
    self.name = ""
  }
}

final class ObjClosure {
  let function: ObjFunction
  var upvalues: [ObjUpvalue]

  init(_ function: ObjFunction) {
    self.function = function
    self.upvalues = []
    self.upvalues.reserveCapacity(function.upvalueCount)
  }
}

final class ObjUpvalue {
  enum Location {
    case slot(Int)
    case closed(Value)
  }
  var location: Location
  var next: ObjUpvalue?

  init(slot: Int) {
    self.location = .slot(slot)
  }

  func getValue(with stack: [Value]) -> Value {
    switch location {
    case .slot(let index): stack[index]
    case .closed(let value): value
    }
  }

  func setValue(_ value: Value, with stack: inout [Value]) {
    switch location {
    case .slot(let index): stack[index] = value
    case .closed: location = .closed(value)
    }
  }
}

struct ObjNative {
  typealias NativeFn = (_ argCount: UInt8, _ args: Int) -> Value
  let function: NativeFn
}