const qs = require('querystring');

module.exports = (req, res, next) => {
  const contentType = req.headers['content-type'];
  const chunks = [];
  req.on('data', (chunk) => chunks.push(chunk) );
  req.on('end', () => {
    let body = Buffer.concat(chunks).toString();
    if (contentType === 'application/json') body = JSON.parse(body);
    if (contentType === 'application/x-www-form-urlencoded') {
      body = qs.parse(body);
      Object.keys(body).forEach((key) => {
        try {
          body[key] = JSON.parse(body[key]);
        } catch(err) {
          return next(err);
        }
      });
    }
    req.body = body;
    next(null, body);
  });
};
