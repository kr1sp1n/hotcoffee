const runHooks = require('./runHooks');

module.exports = (config={}) => {
  const hooks = config.hooks;
  return (req, res) => {
    req.extension = getExtension(req.url);
    res.result = [];
    const method = req.method.toLowerCase();
    const clone = [].concat(...hooks); // fast array clone
    runHooks(req, res, clone, (err) => {
      console.log(err);
    });
  };
};

    //   if err
    //     res.statusCode = if err.statusCode? then err.statusCode else 500
    //     res.result = [ { type: 'error', props: { message: err.message } } ]
    //     @render res
    //     @emit 'error', err
    //   else
    //     if @methods[method]?
    //       @methods[method] req, res
    //     else
    //       err = new Error('Method not supported.')
    //       res.end err.message
    //       @emit 'error', err
    //     @emit 'request', req, res
