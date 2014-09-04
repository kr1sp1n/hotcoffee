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

test-watch:
	$(MOCHA_BIN) --growl --reporter $(MOCHA_REPORTER) --watch --compilers coffee:coffee-script/register --colors $(TEST_UNIT_DIR)

cov:
	$(MOCHA_BIN) $(TEST_UNIT_DIR) -R mocha-spec-cov-alt

cov-html:
	$(MOCHA_BIN) $(TEST_UNIT_DIR) -R html-cov > ./cov.html