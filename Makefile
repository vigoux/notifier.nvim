build:
	tl build

check:
	tl check teal/**/*.tl

ensure: build
	git diff --exit-code -- lua

test:
	./run_tests.sh
