# list deploys - List Known Deploys
# delete deploy <timestamp> - Deletes the deploy referenced by the unix timestamp

time = require('time')

class Deploys
  constructor: (@robot) ->
    @cache = []

    @robot.brain.on 'loaded', =>
      if @robot.brain.data.deploys
        @cache = @robot.brain.data.deploys

  add: (deploy) ->
    @cache.push deploy
    @cache.sort (a, b) -> b.date - a.date
    @robot.brain.data.deploys = @cache

  list: (msg) ->
    deploys = []
    for deploy in @cache
      do (deploy) ->
        deploy_date = new time.Date(deploy.date)
        deploy_date.setTimezone("America/Los_Angeles")

        return_deploy = "" + deploy.environment +
                      " - " + deploy.reference +
                      "/" + deploy.sha1 +
                      ". By: " + deploy.deployer +
                      " on " + deploy_date + " / " + deploy.date + "."

        deploys.push return_deploy

    if deploys.length > 0
      msg.send deploys.join('\n')
    else
      msg.send "No Deploys Recorded"

  delete: (timestamp) ->
    deploys = []
    for deploy in @cache
      do (deploy) ->
        if String(deploy.date) != timestamp
          deploys.push deploy

    @cache = deploys
    @robot.brain.data.deploys = deploys

    if timestamp == 'all'
      @cache = []
      @robot.brain.data.deploys = []

class Deploy
  # Represents a deploy notice
  #
  # deployer   - The deployer's username
  # options    - A hash of key, value pairs for this deploy
  constructor: (deployer, options = { }) ->
    @deployer = deployer
    for k of (options or { })
      @[k] = options[k]

    @date = new Date().getTime()


module.exports = (robot) ->
  deploys = new Deploys robot

  robot.hear /([\w .-]+) has (started|finished) deploying to ([\w .-]+) with ([\w .]+)\/([\w .]+) to \/.+at\s([\w .-].+)/i, (msg) ->
    deployer    = msg.match[1]
    action      = msg.match[2]
    environment = msg.match[3]
    reference   = msg.match[4]
    sha1        = msg.match[5]

    if action == "finished"
      deploy = new Deploy(deployer, {"action":action, "environment":environment, "reference":reference, "sha1":sha1})
      deploys.add deploy


  robot.respond /list deploys/i, (msg) ->
    deploys.list(msg)

  robot.respond /delete deploy ([\w .-]+)/i, (msg) ->
    timestamp = msg.match[1]
    output = deploys.delete(timestamp)
    msg.send "Deleted: " + timestamp + "."
