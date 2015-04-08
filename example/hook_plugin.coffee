# file: example/hook_plugin

module.exports = (app, config)->

	app.hook (req, res, next)->
		console.log "1st hook with 1s delay"
		setTimeout next, 1000

	app.hook (req, res, next)->
		console.log "2nd hook with error"
		next new Error("BAM!")

	return name: 'My 1st hook plugin'
