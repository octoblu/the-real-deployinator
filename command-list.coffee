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

    @dockerUser = commander.user ? 'octoblu'
    @projectName = _.first commander.args
    @quayToken = process.env.DEPLOYINATOR_QUAY_TOKEN

  run: =>
    @parseOptions()

    return @die new Error('Missing DEPLOYINATOR_QUAY_TOKEN in environment') unless @quayToken?
    return @die new Error('Missing project name') unless @projectName?

    @deploy()

  deploy: =>
    console.log ""
    console.log "=>", @projectName
    console.log ""

    options =
      uri: "https://quay.io/api/v1/repository/#{@dockerUser}/#{@projectName}/tag/"
      json: true
      auth:
        bearer: @quayToken

    debug 'requestOptions', options
    request.get options, (error, response, body) =>
      return @die error if error?
      return @die new Error("[#{response.statusCode}] List failed: #{body}") if response.statusCode >= 400
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
