commander   = require 'commander'
packageJSON = require './package.json'

class Command
  run: =>
    commander
      .version packageJSON.version
      .command 'active', 'active color of a deploy'
      .command 'deploy', 'deploy an application'
      .command 'list', 'list available tags'
      .command 'status', 'status of a deploy'
      .command 'rollback', 'rollback a deploy'
      .command 'worker', 'deploy a worker'
      .parse process.argv

    unless commander.runningCommand
      commander.outputHelp()
      process.exit 1

(new Command()).run()
