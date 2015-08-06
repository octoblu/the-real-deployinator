commander   = require 'commander'
packageJSON = require './package.json'

class Command
  run: =>
    commander
      .version packageJSON.version
      .command 'deploy', 'deploy an application'
      .command 'status', 'status of a deploy'
      .command 'rollback', 'rollback a deploy'
      .parse process.argv

    unless commander.runningCommand
      commander.outputHelp()
      process.exit 1

(new Command()).run()
