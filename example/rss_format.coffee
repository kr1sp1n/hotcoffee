# file: example/rss_format.coffee

toRSS = (res, result)->
  resource = res.req.resource
  endpoint = res.endpoint
  output = '<rss version="2.0"><channel>'
  output += '<title>'+resource+'</title>'
  output += '<link>'+endpoint+'/'+resource+'</link>'
  for item in result
    output += '<item><title>'+item.name or item.title+'</title>'
    output += '<description><![CDATA['+JSON.stringify(item)+']]></description></item>'
  output += '</channel></rss>'
  res.setHeader 'Content-Type', 'application/rss+xml; charset=utf-8'
  res.end output

module.exports =
  rss: toRSS
  'application/rss+xml': toRSS
