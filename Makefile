test:
	busted

watch-test:
	fd -e lua | entr -c busted

.PHONY: test
