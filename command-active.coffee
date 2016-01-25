_         = require 'lodash'
colors    = require 'colors'
request   = require 'request'
commander = require 'commander'
jsome     = require 'jsome'
debug     = require('debug')('deployinator:check')

class DeployinatorActive
  parseOptions: =>
    commander
      .usage '[options] <project name>'
      .option '-h, --host <https://deployinate.octoblu.com>',
        'URI where deployinate-service is running (env: DEPLOYINATE_HOST)'
      .option '-p, --pretty', 'Pretty print json [false]'
      .option '-u, --user <octoblu>', 'Docker image user'
      .parse process.argv

    @projectName = _.first commander.args
    @dockerUser = commander.user ? 'octoblu'
    @host = commander.host ? process.env.DEPLOYINATE_HOST || 'https://deployinate.octoblu.com'
    @username = process.env.DEPLOYINATOR_UUID
    @password = process.env.DEPLOYINATOR_TOKEN
    @pretty = commander.pretty ? false

  run: =>
    @parseOptions()

    return @die new Error('Missing DEPLOYINATOR_UUID in environment') unless @username?
    return @die new Error('Missing DEPLOYINATOR_TOKEN in environment') unless @password?
    return @die new Error('Missing DEPLOYINATOR_HOST in environment') unless @host?
    return @die new Error('Missing project name') unless @projectName?

    @deploy()

  deploy: =>
    options =
      uri: "/status/#{@dockerUser}/#{@projectName}"
      baseUrl: @host
      auth: {@username, @password}
      json: true

    debug 'request.get', options
    request.get options, (error, response, body) =>
      return @die error if error?
      return @die new Error("Deploy failed") if response.statusCode >= 400
      active = body?.service?.active
      jsome active: active if @pretty
      console.log JSON.stringify(active: active, null, 2) unless @pretty

  die: (error) =>
    if 'Error' == typeof error
      console.error colors.red error.message
    else
      console.error colors.red arguments...
    process.exit 1

new DeployinatorActive().run()
