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
      .option '-u, --user <user>', 'Docker image user [octoblu]'
      .option '-p, --pretty', 'Pretty print json [false]'
      .parse process.argv

    @project_name = _.first commander.args
    @user = commander.user ? 'octoblu'
    @USERNAME = process.env.DEPLOYINATOR_UUID
    @PASSWORD = process.env.DEPLOYINATOR_TOKEN
    @HOST = process.env.DEPLOYINATOR_HOST
    @pretty = commander.pretty ? false

  run: =>
    @parseOptions()

    return @die new Error('Missing DEPLOYINATOR_UUID in environment') unless @USERNAME?
    return @die new Error('Missing DEPLOYINATOR_TOKEN in environment') unless @PASSWORD?
    return @die new Error('Missing DEPLOYINATOR_HOST in environment') unless @HOST?
    return @die new Error('Missing project name') unless @project_name?

    @deploy()

  deploy: =>
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
