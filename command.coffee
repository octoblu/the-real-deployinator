commander   = require 'commander'
packageJSON = require './package.json'

class Command
  run: =>
    commander
      .version packageJSON.version
      .command 'deploy', 'deploy an application'
      .command 'list', 'list available tags'
      .command 'postpone', 'postpone a deploy'
      .command 'schedule', 'schedule a deploy'
      .command 'status', 'status of a deploy'
      .parse process.argv

    unless commander.runningCommand
      commander.outputHelp()
      process.exit 1

(new Command()).run()
