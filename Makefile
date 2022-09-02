build:
	tl build

check:
	tl check teal/**/*.tl

ensure: build
	git diff --exit-code -- lua

test:
	./run_tests.sh

nix-build:
	nix-shell --pure --run "tl build"

nix-test:
	nix-shell --pure --run "./run_tests.sh"

nix-debug:
	nix-shell --pure --run "nvim --clean -u min.vim"
