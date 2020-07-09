BUSTED_ARGS := -e "TASKPAPER_INDENT_STRING = '  '"

test:
	busted ${BUSTED_ARGS}

watch-test:
	fd -e lua | entr -c busted ${BUSTED_ARGS}

.PHONY: test
