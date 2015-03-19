.PHONY: test

MODULE_DIR = ./node_modules
BIN_DIR = $(MODULE_DIR)/.bin
MOCHA_BIN = $(BIN_DIR)/mocha
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
	$(MOCHA_BIN) $(TEST_UNIT_DIR) --require blanket --compilers coffee:coffee-script/register -R mocha-spec-cov-alt

coveralls:
	NODE_ENV=test $(MOCHA_BIN) $(TEST_UNIT_DIR) --require blanket --compilers coffee:coffee-script/register -R mocha-lcov-reporter | $(BIN_DIR)/coveralls

cov-html:
	$(MOCHA_BIN) $(TEST_UNIT_DIR) --require blanket --compilers coffee:coffee-script/register -R html-cov > ./cov.html
