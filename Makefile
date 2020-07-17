BUSTED_ARGS ?= -e "TASKPAPER_INDENT_STRING = '  '"

source_dirs := bin spec taskpaper
lua_files := $(shell find $(source_dirs) -name '*.lua')
fennel_files := $(shell find $(source_dirs) -name '*.fnl')
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
	find taskpaper -maxdepth 1 -name '*.lua' -exec install -Dm644 -t $(LUADIR)/taskpaper/ {} \;

luacheck:
	luacheck --no-max-line-length taskpaper/ spec/ bin/

test:
	busted --shuffle ${BUSTED_ARGS}

ci: luacheck test

watch-test:
	fd -e lua | entr -c busted ${BUSTED_ARGS}

.PHONY: ci luacheck test watch-test
