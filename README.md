hotcoffee
==============================

[![Build Status](https://img.shields.io/travis/kr1sp1n/hotcoffee.svg?style=flat-square)](https://travis-ci.org/kr1sp1n/hotcoffee)
[![Coverage Status](https://img.shields.io/coveralls/kr1sp1n/hotcoffee.svg?style=flat-square)](https://coveralls.io/r/kr1sp1n/hotcoffee)
[![Download Status](https://img.shields.io/npm/dm/hotcoffee.svg?style=flat-square)](https://www.npmjs.com/package/hotcoffee)
[![Dependency Status](https://img.shields.io/david/kr1sp1n/hotcoffee.svg?style=flat-square)](https://david-dm.org/kr1sp1n/hotcoffee)

[![Flattr this git repo](https://img.shields.io/badge/flattr-this-green.svg?style=flat-square)](https://flattr.com/submit/auto?user_id=krispin&url=https://github.com/kr1sp1n/hotcoffee&title=hotcoffee&language=coffeescript&tags=github&category=software)

REST API that saves everything you can imagine.
You just think about a collection name and add an item to it by sending a POST request with body data.
Then you can manipulate items of a collection.

You need [Node.js](https://nodejs.org/) to run the server locally.
You can install it via [nvm](https://github.com/creationix/nvm).

Install
-----------------------------

```bash
git clone git://github.com/kr1sp1n/hotcoffee.git
cd hotcoffee
make install
```


Run Tests
-----------------------------

```bash
make test
```


Start the example server
-----------------------------

```bash
./node_modules/.bin/coffee example/simple_server.coffee
```


Usage
-----------------------------

### GET a list of all collections

```bash
curl http://localhost:1337/
```

__Response__ would be an empty JSON array as long as you never added an item to any collection.

```JSON
[]
```


### POST a new item to a collection

```bash
curl -X POST -d "name=Donatello&color=purple" http://localhost:1337/turtles
```

__Response__

```JSON
{
  "name": "Donatello",
  "color": "purple"
}
```
