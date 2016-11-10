const parseUrl = require('./parseUrl');
const isRoot = require('./isRoot');
const filterResult = require('./filterResult');

module.exports = (config) => {
  const db = config.db;
  return (req, res) => {
    [ resource, key, value ] = parseUrl(req.url);
    const result = [];
    if (isRoot(req.url)) {
      const keys = Object.keys(db);
      result = keys.map( name => ({ type:'resource', href:[res.endpoint, name].join('/'), props: { name } }));
    } else {
      if (db[resource]) {
        result = filterResult(db[resource], { resource, key, value });
      }
    }
    res.result = result;
    render(res);
  };
};
