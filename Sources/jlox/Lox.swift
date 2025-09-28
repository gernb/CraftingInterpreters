import Foundation

@main
struct Lox {
  static nonisolated(unsafe) private let interpreter = Interpreter()
  static nonisolated(unsafe) private var hadError = false
  static nonisolated(unsafe) private var hadRuntimeError = false

  static func main() throws {
    if CommandLine.arguments.count > 2 {
      print("Usage: jlox [script]")
      // For exit codes, I’m using the conventions defined in the UNIX “sysexits.h” header.
      // It’s the closest thing to a standard I could find.
      exit(64)
    } else if CommandLine.arguments.count == 2 {
      try runFile(CommandLine.arguments[1])
    } else {
      runPrompt()
    }
  }

  private static func runFile(_ path: String) throws {
    let contents = try String(contentsOfFile: path, encoding: .utf8)
    run(source: contents)

    // Indicate an error in the exit code.
    if hadError {
      exit(65)
    }
    if hadRuntimeError {
      exit(70)
    }
  }

  private static func runPrompt() {
    while true {
      print("> ", terminator: "")
      if let line = readLine() {
        run(source: line)
        hadError = false
      } else {
        break
      }
    }
  }

  private static func run(source: String) {
    let scanner = Scanner(source: source)
    let tokens = scanner.scanTokens()
    let parser = Parser(tokens: tokens)
    let statements = parser.parse()

	  // Stop if there was a syntax error.
    if hadError { return }

    interpreter.interpret(statements)
  }

  static func error(line: Int, message: String) {
    report(line: line, where: "", message: message)
  }

  static func error(token: Token, message: String) {
    if token.type == .eof {
      report(line: token.line, where: " at end", message: message)
    } else {
      report(line: token.line, where: " at '\(token.lexeme)'", message: message)
    }
  }

  static func runtimeError(_ error: Interpreter.RuntimeError) {
    print("\(error.message)\n[line \(error.op.line)]")
    hadRuntimeError = true
  }

  private static func report(line: Int, where: String, message: String) {
    print("[line \(line)] Error\(`where`): \(message)")
    hadError = true
  }
}
