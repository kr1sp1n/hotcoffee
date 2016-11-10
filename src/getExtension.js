const path = require('path');
const URL = require('url');

module.exports = (url) => {
  const x = path.extname(URL.parse(url).pathname).split('.');
  if (x.length > 1) return x[1];
  return;
};
