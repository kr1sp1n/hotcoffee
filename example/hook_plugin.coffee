# file: example/hook_plugin.coffee

module.exports = (app, config)->

	app.hook (req, res, next)->
		app.log.info '1st hook with 500 ms delay'
		setTimeout next, 500

	app.hook (req, res, next)->
		app.log.info '2nd hook with error'
		next new Error("BAM!")

	return name: 'My 1st hook plugin'
