mocha := ../node_modules/mocha/bin/mocha --compilers coffee:coffee-script --timeout 10000 --slow 3000 --reporter spec

.PHONY: all

all:
	@$(mocha) .

%:
	@$(mocha) $@.coffee
