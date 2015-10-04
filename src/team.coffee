
class Team
  constructor: (@id, @base, @color, @point = 100)->
    @units = []

  changePoint: (diff)->
    @point += diff
    @point = Math.max 0, @point
    @scoreborad.text = "#{@point}"
    @scoreboradUpdate()

  eachMembers: (f)->
    f u for u in @units

module.exports = Team