module.exports = (config) => {
  return (req, res, next) => {
    res.req = req;
    res.endpoint = config.endpoint;
    next();
  }
};
