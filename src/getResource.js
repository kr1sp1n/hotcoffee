module.exports = (req, res, next) => {
  [resource] = parseURL(req.url);
  req.resource = resource;
  next();
};
