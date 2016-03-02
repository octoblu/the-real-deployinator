_         = require 'lodash'
colors    = require 'colors'
request   = require 'request'
commander = require 'commander'
jsome     = require 'jsome'
debug     = require('debug')('deployinator:check')

class DeployinatorStatus
  parseOptions: =>
    commander
      .usage '[options] <project-name>'
      .option '-h, --host <https://deployinate.octoblu.com>',
        'URI where deployinate-service is running (env: DEPLOYINATE_HOST)'
      .option '-p, --pretty', 'Pretty print json'
      .option '-u, --user <octoblu>', 'Docker image user]'
      .parse process.argv

    @projectName = _.first commander.args
    @host = commander.host ? process.env.DEPLOYINATE_HOST || 'https://deployinate.octoblu.com'
    @dockerUser = commander.user ? 'octoblu'
    @username = process.env.DEPLOYINATOR_UUID
    @password = process.env.DEPLOYINATOR_TOKEN
    @pretty = commander.pretty

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
      return @die new Error("[#{response.statusCode}] Status failed: #{JSON.stringify body}") if response.statusCode >= 400
      jsome body if @pretty
      console.log JSON.stringify(body, null, 2) unless @pretty

  die: (error) =>
    if 'Error' == typeof error
      console.error colors.red error.message
    else
      console.error colors.red arguments...
    process.exit 1

new DeployinatorStatus().run()
