_         = require 'lodash'
colors    = require 'colors'
request   = require 'request'
commander = require 'commander'
debug     = require('debug')('deployinator:schedule')

class DeployinatorSchedule
  parseOptions: =>
    commander
      .usage '[options] <project-name> <tag>'
      .option '-h, --host <https://deployinate.octoblu.com>',
        'URI where deployinate-service is running (env: DEPLOYINATE_HOST)'
      .option '-u, --user <octoblu>', 'Docker image user'
      .parse process.argv

    @host = commander.host ? process.env.DEPLOYINATE_HOST || 'https://deployinate.octoblu.com'
    @dockerUser = commander.user ? 'octoblu'
    @notRelative = commander.notRelative
    [@projectName, @tag, @deployAt] = commander.args

    unless @projectName? && @tag? && @deployAt?
      return @die "projectName, tag, deployAt is required: received '#{@projectName}', '#{@tag}', '#{@deployAt}'"

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
    etcdDir = "/#{@dockerUser}/#{@projectName}"
    dockerUrl = "quay.io/#{@dockerUser}/#{@projectName}:#{@tag}"

    console.log ""
    console.log "=>", "#{etcdDir}:#{dockerUrl}"
    console.log ""

    options =
      uri: "/schedules"
      baseUrl: @host
      auth: {@username, @password}
      json:
        etcdDir: etcdDir
        dockerUrl: dockerUrl
        deployAt: @deployAt

    debug 'request.post', options
    request.post options, (error, response, body) =>
      return @die error if error?
      if response.statusCode >= 400
        return @die new Error("[#{response.statusCode}] Schedule failed: #{JSON.stringify body}")
      debug 'response', body
      console.log 'Schedule Changed', colors.yellow @tag
      console.log ""

  die: (error) =>
    if 'Error' == typeof error
      console.error colors.red error.message
    else
      console.error colors.red arguments...
    process.exit 1

new DeployinatorSchedule().run()
