# list deploys - List Known Deploys
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
        tmp_date = new Date(deploy.date)
        deploy_date = tmp_date.getFullYear().toString() + "/" +
                      (1+tmp_date.getMonth()).toString() + "/" +
                      tmp_date.getDate().toString() + " " +
                      tmp_date.getHours().toString() + ":" +
                      tmp_date.getMinutes().toString() + ":" +
                      tmp_date.getSeconds().toString() + " / " +
                      tmp_date.getTime().toString()

        return_deploy = "Environment: " + deploy.environment + ". Version: " + deploy.reference + ". SHA1: " + deploy.sha1 + ". By: " + 
                        deploy.deployer + " on " + deploy_date + "."
        deploys.push return_deploy

    if deploys.length > 0
      msg.send "These are the deploys I know\n\n" + deploys.join('\n')
    else
      msg.send "I don't know about any deploys"

  delete: (timestamp) ->
    deploys = []
    for deploy in @cache
      do (deploy) ->
        if String(deploy.date) != timestamp
          deploys.push deploy

    if timestamp != 'all'
      @cache = deploys
      @robot.brain.data.deploys = deploys
    else
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
