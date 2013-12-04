http = require 'http'
URL = require 'url'
qs = require 'querystring'
fs = require 'fs'

# parse args
args = {}
process.argv.slice(2).map (a)-> args[a.split('=')[0]] = a.split('=')[1]

port = process.env.PORT or args.port or 1337
host = args.host or '127.0.0.1'
file = false or args.file

db = {}

if file
  unless fs.existsSync(file)
    console.error "File #{file} does not exist."
    process.exit(1)
  try
    db = require file
  catch error
    console.error "File #{file} is invalid JSON."
    process.exit(1)

process.on 'exit', -> onExit()

process.on 'SIGINT', ->
  onExit()
  process.exit(0)

isRoot = (url)-> url == '/'
onExit = -> writeDb()
writeDb = -> fs.writeFileSync(file, JSON.stringify(db)) if file

merge = (dest, source)->
  for key, value of dest
    dest[key] = source[key] if source[key]?
  for key, value of source
    dest[key] = source[key]

writeHead = (res)-> 
  res.writeHead 200, {
    'Content-Type': 'application/json'
    'Access-Control-Allow-Origin': '*'
  }

parseURL = (url)->
  x = URL.parse(url).pathname.split('/')
  x.shift() # remove first empty string element
  return x

parseBody = (req, done)->
  body = ''
  req.on 'data', (data)->
    body += data
  req.on 'end', ->
    body = qs.parse body
    done null, body

onGET = (req, res)->
  [ resource, key, value ] = parseURL req.url
  if isRoot req.url
    result = for name, val of db
      name
  else
    result = db[resource] ?= []
    result = result.filter((x) -> x[key]?) if key? and key.length > 0
    result = result.filter((x) -> x[key] == value) if value?

  render res, result

onPOST = (req, res)->
  [ resource, key, value ] = parseURL req.url
  db[resource] ?= []
  parseBody req, (err, body)->
    console.log err if err?
    db[resource].push body if resource != ""
    render res, body

onPATCH = (req, res)->
  [ resource, key, value ] = parseURL req.url
  db[resource] ?= []
  result = db[resource]
  result = result.filter((x) -> x[key]?) if key?
  result = result.filter((x) -> x[key] == value) if value?
  parseBody req, (err, body)->
    console.log err if err?
    merge k, body for k in result
    render res, result

onDELETE = (req, res)->
  [ resource, key, value ] = parseURL req.url
  db[resource] ?= []
  result = [] # deleted items
  if resource? and not key?
    # delete collection
    result = db[resource].slice(0) # clone array
    delete db[resource]
  else
    # delete items
    db[resource] = db[resource].filter((x) -> (x[key] != value) or (!result.push x))
  render res, result

onHEAD = (req, res)->
  [ resource, key, value ] = parseURL req.url
  result = [] # resource keys
  render res, result

render = (res, result)->
  output = ""
  # unless result
  #   console.log "OUTPUT"
  #   out = result.map (item)->
  #     console.log item
  #     Object.keys(item).map((key)-> item[key]).join("\t")

  #   console.log out

  #   res.end out.join("\n") + "\n"
  # else
  #   res.end "\n"

  # console.log res

  # res.end()
  res.end JSON.stringify(result, null, 2) + '\n'

onRequest = (req, res)->

  writeHead res
  method = req.method.toUpperCase()

  switch method
    when "GET" then onGET req, res
    when "POST" then onPOST req, res
    when "PUT" then console.log "PUT"
    when "PATCH" then onPATCH req, res
    when "DELETE" then onDELETE req, res
    when "HEAD" then onHEAD req, res
    else
      res.end 'Hello World\n'

server = http.createServer onRequest
server.listen port, host
console.log "Server running at http://#{host}:#{port}/"
console.log "with db file #{file}" if file
