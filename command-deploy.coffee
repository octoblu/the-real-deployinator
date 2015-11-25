_         = require 'lodash'
colors    = require 'colors'
request   = require 'request'
commander = require 'commander'
debug     = require('debug')('deployinator:deploy')

class DeployinatorDeploy
  parseOptions: =>
    commander
      .usage '[options] <project name> <tag>'
      .option '-u, --user <user>', '(optional) Docker image user [octoblu]'
      .parse process.argv

    @project_name = _.first commander.args
    @tag = commander.args[1]
    @user = commander.user ? 'octoblu'
    @USERNAME = process.env.DEPLOYINATOR_UUID
    @PASSWORD = process.env.DEPLOYINATOR_TOKEN
    @DOCKER_PASS = process.env.DEPLOYINATOR_DOCKER_PASS
    @HOST = process.env.DEPLOYINATOR_HOST

  run: =>
    @parseOptions()

    return @die new Error('Missing DEPLOYINATOR_UUID in environment') unless @USERNAME?
    return @die new Error('Missing DEPLOYINATOR_TOKEN in environment') unless @PASSWORD?
    return @die new Error('Missing DEPLOYINATOR_DOCKER_PASS in environment') unless @DOCKER_PASS?
    return @die new Error('Missing DEPLOYINATOR_HOST in environment') unless @HOST?
    return commander.outputHelp() unless @project_name? && @tag?

    @deploy()

  deploy: =>
    console.log ""
    console.log "=>", @project_name
    console.log ""

    requestOptions =
      json:
        repository: "#{@user}/#{@project_name}"
        docker_url: "quay.io/#{@user}/#{@project_name}"
        updated_tags: [@tag]
      method: 'POST'
      uri: "https://#{@HOST}/deploy"
      auth:
        user: @USERNAME
        password: @PASSWORD
    debug 'requestOptions', requestOptions
    request requestOptions, (error, response, body) =>
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

new DeployinatorDeploy().run()
