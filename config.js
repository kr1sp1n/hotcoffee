module.exports = () => {
  const host = process.env.HOST || 'localhost';
  const port = process.env.PORT || 1337;
  return {
    port: port,
    host: host,
    endpoint: process.env.ENDPOINT || `http://${host}:${port}`
  };
};
