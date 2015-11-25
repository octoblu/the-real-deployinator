_         = require 'lodash'
colors    = require 'colors'
request   = require 'request'
commander = require 'commander'
jsome     = require 'jsome'
debug     = require('debug')('deployinator:check')

class DeployinatorRollback
  parseOptions: =>
    commander
      .usage '[options] <project name>'
      .option '-u, --user <user>', 'Docker image user [octoblu]'
      .parse process.argv

    @project_name = _.first commander.args
    @user = commander.user ? 'octoblu'
    @USERNAME = process.env.DEPLOYINATOR_UUID
    @PASSWORD = process.env.DEPLOYINATOR_TOKEN
    @HOST = process.env.DEPLOYINATOR_HOST

  run: =>
    @parseOptions()

    return @die new Error('Missing DEPLOYINATOR_UUID in environment') unless @USERNAME?
    return @die new Error('Missing DEPLOYINATOR_TOKEN in environment') unless @PASSWORD?
    return @die new Error('Missing DEPLOYINATOR_HOST in environment') unless @HOST?
    return @die new Error('Missing project name') unless @project_name?

    @deploy()

  deploy: =>
    console.log ""
    console.log "=>", @project_name
    console.log ""

    requestOptions =
      json: true
      method: 'GET'
      uri: "https://#{@HOST}/status/#{@user}/#{@project_name}"
      auth:
        user: @USERNAME
        password: @PASSWORD
    debug 'requestOptions', requestOptions
    request requestOptions, (error, response, body) =>
      return @die error if error?
      return @die new Error("[#{response.statusCode}] Rollback failed: #{body}") if response.statusCode >= 400
      activeColor = body?.service?.active

      console.log "Active color is: #{colors[activeColor] activeColor}"
      if activeColor == 'green'
        newColor = 'blue'
      else
        newColor = 'green'
      console.log "Switching to #{colors[newColor] newColor}"

      requestOptions =
        json: true
        method: 'POST'
        uri: "https://#{@HOST}/rollback/#{@user}/#{@project_name}"
        auth:
          user: @USERNAME
          password: @PASSWORD
      debug 'requestOptions', requestOptions
      request requestOptions, (error, response, body) =>
        return @die error if error?
        return @die new Error("Rollback failed") if response.statusCode >= 400

        console.log "Started healthcheck for #{colors[newColor] "#{@user}-#{@project_name}-#{newColor}"}"
        console.log ""

        process.exit 0

  die: (error) =>
    if 'Error' == typeof error
      console.error colors.red error.message
    else
      console.error colors.red arguments...
    process.exit 1

new DeployinatorRollback().run()
