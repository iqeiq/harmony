
class Team
  constructor: (@id, @base, @core, @color, @point = 100)->
    @units = []
    @bullets = []

  changePoint: (diff)->
    @point += diff
    @point = Math.max 0, @point
    @scoreboradUpdate()

  eachMembers: (f)->
    f u for u in @units

module.exports = Team