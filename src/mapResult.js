module.exports = (config) => {
  const formats = config.formats;
  return (res) => {
    if (formats) {
      extension = res.req.extension;
      accept = res.req.headers['accept'];
      format = 'json';
      if (formats[extension]) {
        format = extension;
      } else if (formats[accept]) {
        format = accept;
      }
      formats[format](res);
    }
  };
};
