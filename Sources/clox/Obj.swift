enum Obj {
  case function(ObjFunction)
  case native(ObjNative)
  case string(String)

  var isFunction: Bool { type == .function }
  var isNative: Bool { type == .native }
  var isString: Bool { type == .string }

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
    case .function: .function
    case .native: .native
    case .string: .string
    }
  }

  enum ObjType {
    case function, native, string
  }
}

extension Obj {
  static func == (lhs: Self, rhs: Self) -> Bool {
    guard lhs.type == rhs.type else { return false }
    return switch (lhs.type) {
    case .function, .native: false
    case .string: lhs.asString == rhs.asString
    }
  }
}

extension Obj: CustomStringConvertible {
  var description: String {
    switch self {
    case .function(let value): value.name.isEmpty ? "<script>" : "<fn \(value.name)>"
    case .native: "<native fn>"
    case .string(let value): value
    }
  }
}

extension Obj: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
   self = .string(value)
  }
}

struct ObjFunction {
  var arity: Int
  var chunk: Chunk
  var name: String

  init() {
    self.arity = 0
    self.chunk = Chunk()
    self.name = ""
  }
}

struct ObjNative {
  typealias NativeFn = (_ argCount: UInt8, _ args: Int) -> Value
  let function: NativeFn
}