MODULES = difftest
MLFILES = $(addsuffix .ml, $(MODULES))
CMOFILES = $(addsuffix .cmo, $(MODULES))
CMXFILES = $(addsuffox .cmx, $(MODULES))

%.cmi: %.mli
	ocamlc -g -c $<

%.cmx: %.ml
	ocamlopt -g -c $<

%.cmo: %.ml
	ocamlc -g -c $<

all: difftest.cmi difftest.cmx
	ocamlopt -g -o difftest unix.cmxa difftest.cmx

test : difftest
	@(if command -v diff >/dev/null 2>&1; then \
		printf "\x1b[1mRunning Diff Test \x1b[0m\n" ; \
		./difftest ; \
	else echo "You need to install the command `diff` for testing."; \
	fi)

test-update : difftest
	@(if command -v dwdiff >/dev/null 2>&1; then \
		printf "\x1b[1mRunning Diff Test \x1b[0m\n" ; \
		./difftest -u true ; \
	else echo "You need to install the command `dwdiff` for testing."; \
	fi)
