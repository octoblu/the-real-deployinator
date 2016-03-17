_         = require 'lodash'
cliClear  = require 'cli-clear'
colors    = require 'colors'
Mustache  = require 'mustache'
fs        = require 'fs'
moment    = require 'moment'
path      = require 'path'
request   = require 'request'
commander = require 'commander'
debug     = require('debug')('deployinator:check')

class DeployinatorWatch
  parseOptions: =>
    commander
      .usage '[options] <project-name>'
      .option '-h, --host <https://deployinate.octoblu.com>',
        'URI where deployinate-service is running (env: DEPLOYINATE_HOST)'
      .option '-i, --interval <5>', 'Interval to run (in seconds)', 5, commander.parseInt
      .option '-j, --json', 'Print json'
      .option '-l, --lines <40>', 'Truncate output to fit on the screen', 40, commander.parseInt
      .option '-u, --user <octoblu>', 'Docker image user]'
      .parse process.argv

    @projectName = _.first commander.args
    @host = commander.host ? process.env.DEPLOYINATE_HOST || 'https://deployinate.octoblu.com'
    @dockerUser = commander.user ? 'octoblu'
    @interval = commander.interval
    @lines    = commander.lines
    @username = process.env.DEPLOYINATOR_UUID
    @password = process.env.DEPLOYINATOR_TOKEN
    @json = commander.json

  run: =>
    @parseOptions()

    return @die new Error('Missing DEPLOYINATOR_UUID in environment') unless @username?
    return @die new Error('Missing DEPLOYINATOR_TOKEN in environment') unless @password?
    return @die new Error('Missing DEPLOYINATOR_HOST in environment') unless @host?
    return @die new Error('Missing project name') unless @projectName?

    @singleRun()

  singleRun: =>
    @getStatus (error, status) =>
      return @die error if error?
      cliClear()
      setTimeout @singleRun, (1000 * @interval)
      return @printJSON status if @json
      return @printHumanReadable status

  getStatus: (callback) =>
    options =
      uri: "/status/#{@dockerUser}/#{@projectName}"
      baseUrl: @host
      auth: {@username, @password}
      json: true

    debug 'request.get', options
    request.get options, (error, response, body) =>
      return callback error if error?
      if response.statusCode >= 400
        return callback new Error("[#{response.statusCode}] Status failed: #{JSON.stringify body}")
      callback null, body

  printJSON: (data) =>
    console.log JSON.stringify(data, null, 2)

  printHumanReadable: (data) =>
    context = _.cloneDeep data
    context.majorVersion = @formatVersion context.majorVersion
    context.minorVersion = @formatVersion context.minorVersion
    context.status.travis = @formatTravisStatus context.status.travis
    context.deployments = _.map data.deployments, @formatDeployment
    context.deployments = _.sortBy context.deployments, 'deployAt'
    context.servers = _.map data.servers, (url, name) => {name, url}
    context.servers = _.sortBy context.servers, 'name'
    context.status.quay = @formatQuayStatus context.quay

    template = fs.readFileSync(path.join(__dirname, 'status-template.eco'), 'utf-8')
    output = Mustache.render template, {context}

    console.log new Date()
    console.log @head(output, lines: @lines)

  formatDeployment: (deployment) =>
    deployment = _.cloneDeep deployment
    deployment.deployAt = colors.cyan moment.unix(deployment.deployAt).format('llll')

    if deployment.status == 'pending'
      deployment.status = colors.yellow deployment.status
    else
      deployment.status = colors.red deployment.status

    return deployment

  formatTravisStatus: (msg) =>
    return colors.green msg if _.contains msg, 'successful'
    return colors.yellow msg if _.contains msg, 'checking'
    return colors.red msg

  formatQuayStatus: (build) =>
    return 'unknown' unless build?

    {tag, phase}  = build
    msg = "#{phase}: #{tag}"
    return colors.green msg if phase == 'complete'
    return colors.yellow msg if phase == 'building'
    return colors.yellow msg if phase == 'pulling'
    return colors.yellow msg if phase == 'build-scheduled'
    return colors.yellow msg if phase == 'pushing'
    return colors.cyan msg if phase == 'waiting'
    return colors.red msg

  formatVersion: (version) =>
    return colors.red('unknown') unless version?
    colors.magenta version

  head: (str, {lines=40}={}) =>
    str.split('\n')[0..lines].join('\n')

  die: (error) =>
    if 'Error' == typeof error
      console.error colors.red error.message
    else
      console.error colors.red arguments...
    process.exit 1

new DeployinatorWatch().run()
