BUSTED_ARGS := -e "TASKPAPER_INDENT_STRING = '  '"

test:
	luacheck taskpaper/ spec/ && busted --shuffle ${BUSTED_ARGS}

watch-test:
	fd -e lua | entr -c busted ${BUSTED_ARGS}

.PHONY: test
