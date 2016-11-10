// file: src/parseUrl.js

const URL = require('url');
const getExtension = require('./getExtension');

module.exports = (url) => {
  const x = URL.parse(url).pathname.split('/');
  x.shift() // remove first empty string element
  const ext = getExtension(url);
  if (ext) {
    [last, ...rest] = x.reverse();
    x[x.length-1] = last.split('.')[0];
  }
  return x
};
