
toRSS = (res, result)->
  resource = res.req.resource
  output = '<?xml version="1.0" encoding="utf-8"?>'
  output += '<rss version="2.0"><channel>'
  output += '<title>'+resource+'</title>'
  for item in result
    output += '<item><title>'+item.name+'</title>'
    output += '<description>'+JSON.stringify(item)+'</description></item>'
  output += '</channel></rss>'
  res.setHeader 'Content-Type', 'application/xml+rss'
  res.end output

exports.rss = toRSS
exports['application/rss+xml'] = toRSS
