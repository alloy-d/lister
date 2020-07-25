BUSTED_ARGS ?= --helper "spec/setup.lua" # -v

# TODO: only apply these exceptions to fennel-generated code.
# 212 == unused variable length argument.
# 311 == value assigned to variable is overwritten before use.
# 541 == empty do..end block; produced by fennel when importing macros.
LUACHECK_ARGS ?= --codes --no-max-line-length --ignore 212 311 541

source_dirs := bin lister lister/things spec taskpaper tools
lua_files := $(shell find $(source_dirs) -name '*.lua')
fennel_files := $(shell find $(source_dirs) -name '*.fnl' -not -name '*_macros.fnl')
compiled_lua_files := $(fennel_files:.fnl=.lua)

%.lua: %.fnl
	fennel --compile $< > $@

all: build bin/lister .git/info/exclude

.git/info/exclude: $(compiled_lua_files)
	echo "" > $@
	for f in $(compiled_lua_files); do \
		echo "$$f" >> $@ ;\
	done

build: $(compiled_lua_files) bin/lister

bin/lister: bin/lister.lua
	echo "#!/usr/bin/env lua" > $@
	cat < $< >> $@

clean:
	rm -f bin/lister $(compiled_lua_files)

install: bin/lister $(compiled_lua_files) $(lua_files)
	install -Dm755 -t $(BINDIR) bin/lister
	for d in $(source_dirs); do \
		find "$$d" -maxdepth 1 -name '*.lua' -exec install -Dm644 -t "$(LUADIR)/$$d/" {} \; ;\
	done

luacheck:
	luacheck $(LUACHECK_ARGS) -- $(source_dirs)

test: $(compiled_lua_files)
	busted ${BUSTED_ARGS}

ci:
	$(MAKE) luacheck
	$(MAKE) test BUSTED_ARGS="$(BUSTED_ARGS) --shuffle"

watch-test:
	sh -c "echo Makefile; fd -e lua -e fnl" | entr -c $(MAKE) -s test

.PHONY: ci clean luacheck test watch-test
