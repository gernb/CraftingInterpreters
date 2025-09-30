import Foundation

@main
struct Lox {
  nonisolated(unsafe) private static let vm = VM()

  static func main() {
    if CommandLine.arguments.count == 1 {
      repl()
    } else if CommandLine.arguments.count == 2 {
      runFile(CommandLine.arguments[1])
    } else {
      print("Usage: clox [path]")
      // For exit codes, I’m using the conventions defined in the UNIX “sysexits.h” header.
      // It’s the closest thing to a standard I could find.
      exit(64)
    }
  }

  private static func repl() {
    while true {
      print("> ", terminator: "")
      if let line = readLine() {
        vm.interpret(line)
      } else {
        break
      }
    }
  }

  private static func runFile(_ path: String) {
    let contents: String
    do {
      contents = try String(contentsOfFile: path, encoding: .utf8)
    } catch {
      print(String(describing: error))
      exit(74)
    }
    let result = vm.interpret(contents)
    switch result {
    case .compileError: exit(65)
    case .runtimeError: exit(79)
    case .ok: break
    }
  }
}
