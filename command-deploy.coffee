_         = require 'lodash'
colors    = require 'colors'
request   = require 'request'
commander = require 'commander'
debug     = require('debug')('deployinator:deploy')

class DeployinatorDeploy
  parseOptions: =>
    commander
      .usage '[options] <project name>'
      .option '-t, --tag <tag>', 'Tag to deploy'
      .option '-u, --user <user>', '(optional) Docker image user [octoblu]'
      .parse process.argv

    @project_name = _.first commander.args
    @tag = commander.tag
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
    return @die new Error('Missing project name') unless @project_name?
    return @die new Error('Missing tag to deploy') unless @tag?

    @deploy()

  deploy: =>
    requestOptions =
      json:
        repository: "#{@user}/#{@project_name}"
        docker_url: "quay.io/#{@user}/#{@project_name}"
        updated_tags:
          "#{@tag}": "#{@DOCKER_PASS}"
      method: 'POST'
      uri: "https://#{@HOST}/deploy"
      auth:
        user: @USERNAME
        password: @PASSWORD
    debug 'requestOptions', requestOptions
    request requestOptions, (error, response, body) =>
      return @die error if error?
      return @die new Error("Deploy failed") if response.statusCode >= 400
      debug 'response', body
      console.log 'it has been done.'

  die: (error) =>
    if 'Error' == typeof error
      console.error colors.red error.message
    else
      console.error colors.red arguments...
    process.exit 1

new DeployinatorDeploy().run()
