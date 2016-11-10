
function runHooks(req, res, hooks, done) {
  if (hooks.length === 0) return done();
  hooks.shift()(req, res, (err) => {
    if (err) return done(err);
    runHooks(req, res, hooks, done);
  });
};

module.exports = runHooks;
