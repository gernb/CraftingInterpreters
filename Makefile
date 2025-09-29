CONFIG = debug

clox:
	swift build -c ${CONFIG} --target clox

jlox: generated
	swift build -c ${CONFIG} --target jlox

generated:
	rm -rf Sources/jlox/Generated
	mkdir Sources/jlox/Generated
	swift tools/generate_ast.swift Sources/jlox/Generated

clean:
	swift package clean
	rm -rf Sources/jlox/Generated
