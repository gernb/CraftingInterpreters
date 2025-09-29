enum Memory {
  static func growCapacity(_ capacity: Int) -> Int {
    capacity < 8 ? 8 : capacity * 2
  }
}