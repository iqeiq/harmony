ACTION = require './actions'

class Unit 
  constructor: (@team, @brain)->
    @pos = {x: 0, y: 0}
    @ang = 0
    @shotang = 0.0
    @size = 0.2
    @vel = 0.0

  getCollider: ->
    colls = []
    rad = @ang * Math.PI / 180
    colls.push
      x: @pos.x + @size * Math.cos rad
      y: @pos.y + @size * Math.sin rad
    ###
    rad = (@ang - 150) * Math.PI / 180
    colls.push
      x: @pos.x + @size * Math.cos rad
      y: @pos.y + @size * Math.sin rad
    rad = (@ang + 150) * Math.PI / 180
    colls.push
      x: @pos.x + @size * Math.cos rad
      y: @pos.y + @size * Math.sin rad
    ###
    colls

  action: (actions)->
    moveflag = 0
    aimflag = false
    shotflag = false
    angs = [undefined, -90, 90, undefined, 180, -135, 135, 180, 0, -45, 45, 0, undefined, -90, 90, undefined]
    for act in actions
      switch act
        when ACTION.MOVE.TOP
          moveflag += 1
        when ACTION.MOVE.BOTTOM
          moveflag += 2
        when ACTION.MOVE.LEFT
          moveflag += 4
        when ACTION.MOVE.RIGHT
          moveflag += 8  
        when ACTION.ATTACK.AIM
          aimflag = true
          shotflag = true
        when ACTION.ATTACK.FOWARD
          shotflag = true
    if angs[moveflag]?
      @ang = angs[moveflag]
      @vel = if aimflag then 0.04 else 0.07
    else
      @vel = 0

    if shotflag
      0 #TODO

  update: ()->
    @action @brain.update(@)

    rad = @ang * Math.PI / 180
    @pos.x += @vel * Math.cos rad
    @pos.y += @vel * Math.sin rad
    @vel = @vel * 0.7
    @vel = 0.0 if @vel * @vel < 0.0001


module.exports = Unit
