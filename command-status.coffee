_         = require 'lodash'
colors    = require 'colors'
Mustache  = require 'mustache'
fs        = require 'fs'
moment    = require 'moment'
path      = require 'path'
request   = require 'request'
commander = require 'commander'
debug     = require('debug')('deployinator:check')

class DeployinatorStatus
  parseOptions: =>
    commander
      .usage '[options] <project-name>'
      .option '-h, --host <https://deployinate.octoblu.com>',
        'URI where deployinate-service is running (env: DEPLOYINATE_HOST)'
      .option '-j, --json', 'Print json'
      .option '-u, --user <octoblu>', 'Docker image user]'
      .parse process.argv

    @projectName = _.first commander.args
    @host = commander.host ? process.env.DEPLOYINATE_HOST || 'https://deployinate.octoblu.com'
    @dockerUser = commander.user ? 'octoblu'
    @username = process.env.DEPLOYINATOR_UUID
    @password = process.env.DEPLOYINATOR_TOKEN
    @json = commander.json

  run: =>
    @parseOptions()

    return @die new Error('Missing DEPLOYINATOR_UUID in environment') unless @username?
    return @die new Error('Missing DEPLOYINATOR_TOKEN in environment') unless @password?
    return @die new Error('Missing DEPLOYINATOR_HOST in environment') unless @host?
    return @die new Error('Missing project name') unless @projectName?

    @getStatus (error, status) =>
      return @die error if error?
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
    context.servers = _.map data.servers, (url, name) => {name, url}

    template = fs.readFileSync(path.join(__dirname, 'status-template.eco'), 'utf-8')
    console.log Mustache.render template, {context}

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

  formatVersion: (version) =>
    return colors.red('unknown') unless version?
    colors.magenta version



  die: (error) =>
    if 'Error' == typeof error
      console.error colors.red error.message
    else
      console.error colors.red arguments...
    process.exit 1

new DeployinatorStatus().run()
