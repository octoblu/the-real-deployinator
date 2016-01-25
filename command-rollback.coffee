_         = require 'lodash'
colors    = require 'colors'
request   = require 'request'
commander = require 'commander'
jsome     = require 'jsome'
debug     = require('debug')('deployinator:check')

class DeployinatorRollback
  parseOptions: =>
    commander
      .usage '[options] <project-name>'
      .option '-h, --host <https://deployinate.octoblu.com>',
        'URI where deployinate-service is running (env: DEPLOYINATE_HOST)'
      .option '-u, --user <octoblu>', 'Docker image user'
      .parse process.argv

    @projectName = _.first commander.args
    @host = commander.host ? process.env.DEPLOYINATE_HOST || 'https://deployinate.octoblu.com'
    @user = commander.user ? 'octoblu'

    @username = process.env.DEPLOYINATOR_UUID
    @password = process.env.DEPLOYINATOR_TOKEN

  run: =>
    @parseOptions()

    return @die new Error('Missing DEPLOYINATOR_UUID in environment') unless @username?
    return @die new Error('Missing DEPLOYINATOR_TOKEN in environment') unless @password?
    return @die new Error('Missing DEPLOYINATOR_HOST in environment') unless @host?
    return @die new Error('Missing project-name') unless @projectName?

    @deploy()

  deploy: =>
    console.log ""
    console.log "=>", @projectName
    console.log ""

    options =
      uri: "/status/#{@user}/#{@projectName}"
      baseUrl: @host
      auth: {@username, @password}
      json: true

    debug 'request.get', options
    request.get options, (error, response, body) =>
      return @die error if error?
      return @die new Error("[#{response.statusCode}] Rollback failed: #{body}") if response.statusCode >= 400
      activeColor = body?.service?.active

      console.log "Active color is: #{colors[activeColor] activeColor}"

      if activeColor == 'green'
        newColor = 'blue'
      else
        newColor = 'green'

      console.log "Switching to #{colors[newColor] newColor}"

      options =
        uri: "/rollback/#{@user}/#{@projectName}"
        baseUrl: @host
        auth: {@username, @password}
        json: true

      debug 'request.post', options
      request.post options, (error, response, body) =>
        return @die error if error?
        return @die new Error("Rollback failed") if response.statusCode >= 400

        healthcheckRecord = "#{@user}-#{@projectName}-#{newColor}"
        console.log "Started healthcheck for #{colors[newColor] healthcheckRecord}"
        console.log ""

        process.exit 0

  die: (error) =>
    if 'Error' == typeof error
      console.error colors.red error.message
    else
      console.error colors.red arguments...
    process.exit 1

new DeployinatorRollback().run()
