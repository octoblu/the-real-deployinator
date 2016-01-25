_         = require 'lodash'
colors    = require 'colors'
request   = require 'request'
commander = require 'commander'
debug     = require('debug')('deployinator:deploy')

class DeployinatorWorker
  parseOptions: =>
    commander
      .usage '[options] <project-name> <tag>'
      .option '-h, --host <https://deployinate.octoblu.com>',
        'URI where deployinate-service is running (env: DEPLOYINATE_HOST)'
      .option '-u, --user <octoblu>', 'Docker image user', 'octoblu'
      .parse process.argv

    @projectName = _.first commander.args
    @host = commander.host ? process.env.DEPLOYINATE_HOST || 'https://deployinate.octoblu.com'
    @tag = commander.args[1]
    @dockerUser = commander.user
    @username = process.env.DEPLOYINATOR_UUID
    @password = process.env.DEPLOYINATOR_TOKEN

  run: =>
    @parseOptions()

    return @die new Error('Missing DEPLOYINATOR_UUID in environment') unless @username?
    return @die new Error('Missing DEPLOYINATOR_TOKEN in environment') unless @password?
    return @die new Error('Missing DEPLOYINATOR_HOST in environment') unless @host?
    return commander.outputHelp() unless @projectName? && @tag?

    @deploy()

  deploy: =>
    console.log ""
    console.log "=>", @projectName
    console.log ""

    options =
      uri: "/workers/deploy"
      baseUrl: @host
      auth: {@username, @password}
      json:
        repository: "#{@dockerUser}/#{@projectName}"
        docker_url: "quay.io/#{@dockerUser}/#{@projectName}"
        updated_tags: [@tag]

    debug 'request.post', options
    request.post options, (error, response, body) =>
      return @die error if error?
      return @die new Error("[#{response.statusCode}] Deploy failed: #{body}") if response.statusCode >= 400
      debug 'response', body
      console.log 'Deployed', colors.yellow @tag
      console.log ""

  die: (error) =>
    if 'Error' == typeof error
      console.error colors.red error.message
    else
      console.error colors.red arguments...
    process.exit 1

new DeployinatorWorker().run()
