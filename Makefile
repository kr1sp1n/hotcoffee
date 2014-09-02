.PHONY: test

MOCHA_BIN = ./node_modules/.bin/mocha
TEST_UNIT_DIR = ./test/unit
MOCHA_REPORTER = spec

install:
	npm install

clean:
	rm -rf ./node_modules

test: test-unit

test-unit: $(MOCHA_BIN)
	$(MOCHA_BIN) --growl --reporter $(MOCHA_REPORTER) --compilers coffee:coffee-script/register --colors $(TEST_UNIT_DIR)

$(MOCHA_BIN): install
