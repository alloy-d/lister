BUSTED_ARGS ?= -e "TASKPAPER_INDENT_STRING = '  '"

# 541 == empty do..end block; produced by fennel when importing macros.
LUACHECK_ARGS ?= --no-max-line-length --ignore 541

source_dirs := bin lister spec taskpaper tools
lua_files := $(shell find $(source_dirs) -name '*.lua')
fennel_files := $(shell find $(source_dirs) -name '*.fnl' -not -name '*_macros.fnl')
compiled_lua_files := $(fennel_files:.fnl=.lua)

%.lua: %.fnl
	fennel --compile $< > $@

build: $(compiled_lua_files)

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

test:
	busted --shuffle ${BUSTED_ARGS}

ci: luacheck test

watch-test:
	fd -e lua | entr -c busted ${BUSTED_ARGS}

.PHONY: ci clean luacheck test watch-test
