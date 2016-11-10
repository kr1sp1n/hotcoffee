module.exports = (res) => {
  const result = res.result.map((item) => {
    if(!item.href) item.href = [res.endpoint, item.type, 'id', item.props.id].join('/');
    return item
  });
  const output = {
    success: true,
    items: result,
    href: res.endpoint + res.req.url
  };
  if (String(res.statusCode).match(/^5|^4/)) output.success = false;
  res.setHeader('Content-Type', 'application/json');
  const str = JSON.stringify(output, null, 2) + '\n'
  res.end(str);
};
