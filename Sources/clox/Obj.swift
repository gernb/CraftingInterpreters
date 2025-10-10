enum Obj {
  indirect case boundMethod(ObjBoundMethod)
  case `class`(ObjClass)
  case closure(ObjClosure)
  case function(ObjFunction)
  case instance(ObjInstance)
  case native(ObjNative)
  case string(String)
  case upvalue(ObjUpvalue)

  var isBoundMethod: Bool { type == .boundMethod }
  var isClass: Bool { type == .class }
  var isClosure: Bool { type == .closure }
  var isFunction: Bool { type == .function }
  var isInstance: Bool { type == .instance }
  var isNative: Bool { type == .native }
  var isString: Bool { type == .string }

  var asBoundMethod: ObjBoundMethod? {
    guard case .boundMethod(let value) = self else { return nil }
    return value
  }
  var asClosure: ObjClosure? {
    guard case .closure(let value) = self else { return nil }
    return value
  }
  var asClass: ObjClass? {
    guard case .class(let value) = self else { return nil }
    return value
  }
  var asFunction: ObjFunction? {
    guard case .function(let value) = self else { return nil }
    return value
  }
  var asInstance: ObjInstance? {
    guard case .instance(let value) = self else { return nil }
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
    case .boundMethod: .boundMethod
    case .class: .class
    case .closure: .closure
    case .function: .function
    case .instance: .instance
    case .native: .native
    case .string: .string
    case .upvalue: .upvalue
    }
  }

  enum ObjType {
    case boundMethod, `class`, closure, function, instance, native, string, upvalue
  }
}

extension Obj {
  static func == (lhs: Self, rhs: Self) -> Bool {
    guard lhs.type == rhs.type else { return false }
    return switch (lhs.type) {
    case .boundMethod, .closure, .function, .native, .upvalue: false
    case .class: lhs.asClass?.name == rhs.asClass?.name
    case .instance: lhs.asInstance === rhs.asInstance
    case .string: lhs.asString == rhs.asString
    }
  }
}

extension Obj: CustomStringConvertible {
  var description: String {
    switch self {
    case .boundMethod(let value): value.method.function.description
    case .class(let value): value.name
    case .closure(let value): value.function.description
    case .function(let value): value.description
    case .instance(let value): "\(value.klass.name) instance"
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
extension ObjFunction: CustomStringConvertible {
  var description: String {
    name.isEmpty ? "<script>" : "<fn \(name)>"
  }
}

struct ObjNative {
  typealias NativeFn = (_ argCount: UInt8, _ args: Int) -> Value
  let function: NativeFn
}

final class ObjClosure {
  let function: ObjFunction
  let upvalues: [ObjUpvalue]

  init(_ function: ObjFunction, upvalues: [ObjUpvalue] = []) {
    self.function = function
    self.upvalues = upvalues
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

  func getValue(with stack: VM.Stack) -> Value {
    switch location {
    case .slot(let index): stack[index]
    case .closed(let value): value
    }
  }

  func setValue(_ value: Value, with stack: inout VM.Stack) {
    switch location {
    case .slot(let index): stack[index] = value
    case .closed: location = .closed(value)
    }
  }
}

final class ObjClass {
  let name: String
  var methods: [String: Value]

  init(name: String) {
    self.name = name
    self.methods = [:]
  }
}

final class ObjInstance {
  let klass: ObjClass
  var fields: [String: Value]

  init(_ klass: ObjClass) {
    self.klass = klass
    self.fields = [:]
  }
}

struct ObjBoundMethod {
  let receiver: Value
  let method: ObjClosure
}