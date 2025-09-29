struct ReturnException: Error, @unchecked Sendable {
  let value: Object
}