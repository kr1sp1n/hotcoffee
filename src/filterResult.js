module.exports = (result, filterBy={}) => {
  ({ resource, key, value } = filterBy);
  if (key && key.length > 0) result = result.filter((x) => x.props[key]);
  if (value) result = result.filter((x) => String(x.props[key]) == decodeURIComponent(String(value)));
  return result;
};
