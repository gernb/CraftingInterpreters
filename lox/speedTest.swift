import Foundation

func fib(_ n: Int) -> Int {
  guard n >= 2 else { return n }
  return fib(n - 1) + fib(n - 2)
}

let before = Date().timeIntervalSince1970
print(fib(40))
let after = Date().timeIntervalSince1970
print(after - before)
