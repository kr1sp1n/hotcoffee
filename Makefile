.PHONY: test

MODULE_DIR = ./node_modules
BIN_DIR = $(MODULE_DIR)/.bin
MOCHA_BIN = $(BIN_DIR)/mocha
TEST_UNIT_DIR = ./test/unit
MOCHA_REPORTER = spec
NODE_DEV_BIN = $(BIN_DIR)/node-dev

install:
	npm install

clean:
	rm -rf ./node_modules

dev-start:
	$(NODE_DEV_BIN) index.coffee

test: test-unit

test-unit: $(MOCHA_BIN)
	$(MOCHA_BIN) --growl --reporter $(MOCHA_REPORTER) --compilers coffee:coffee-script/register --colors $(TEST_UNIT_DIR)

test-watch:
	$(MOCHA_BIN) --growl --reporter $(MOCHA_REPORTER) --watch --compilers coffee:coffee-script/register --colors $(TEST_UNIT_DIR)

cov:
	$(MOCHA_BIN) $(TEST_UNIT_DIR) -R mocha-spec-cov-alt

cov-html:
	$(MOCHA_BIN) $(TEST_UNIT_DIR) -R html-cov > ./cov.html