_         = require 'lodash'
colors    = require 'colors'
request   = require 'request'
commander = require 'commander'
jsome     = require 'jsome'
debug     = require('debug')('deployinator:check')
semverCompare = require 'semver-compare'

class DeployinatorList
  parseOptions: =>
    commander
      .usage '[options] <project name>'
      .option '-u, --user <user>', 'Docker image user [octoblu]'
      .parse process.argv

    @project_name = _.first commander.args
    @user = commander.user ? 'octoblu'
    @QUAY_TOKEN = process.env.DEPLOYINATOR_QUAY_TOKEN

  run: =>
    @parseOptions()

    return @die new Error('Missing DEPLOYINATOR_QUAY_TOKEN in environment') unless @QUAY_TOKEN?
    return @die new Error('Missing project name') unless @project_name?

    @deploy()

  deploy: =>
    requestOptions =
      json: true
      method: 'GET'
      uri: "https://quay.io/api/v1/repository/#{@user}/#{@project_name}/tag/"
      auth:
        bearer: @QUAY_TOKEN
    debug 'requestOptions', requestOptions
    request requestOptions, (error, response, body) =>
      return @die error if error?
      return @die new Error("List failed") if response.statusCode >= 400
      console.log ""
      console.log "=>", @project_name
      console.log ""
      console.log colors.green "Available Tags"
      console.log colors.gray  "=============="
      tags = _.uniq _.pluck body?.tags, 'name'
      console.log tags.sort(semverCompare).join("\n")
      console.log ""

  die: (error) =>
    if 'Error' == typeof error
      console.error colors.red error.message
    else
      console.error colors.red arguments...
    process.exit 1

new DeployinatorList().run()
