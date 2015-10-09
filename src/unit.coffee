ACTION = require './actions'
STATUS = require './status'
util = require './util'

class Unit 
  constructor: (@team, @base, @brain)->
    @pos = {x: 0, y: 0}
    @ang = if @team % 2 then 180 else 0
    @shotang = 0.0
    @fullhp = 5
    @hp = @fullhp
    @size = 0.2
    @vel = 0.0
    @shotInterval = 0
    @status = STATUS.ACTIVE
    @respawnCount = 0

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

  action: (actions, shot, near)->
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
      @vel = if aimflag then 0.03 else 0.06
    else
      @vel = 0

    @shotang = @ang 
    @shotInterval-- if @shotInterval > 0

    if shotflag and @shotInterval is 0
      if aimflag
        a = near @pos, 5
        @shotang = a if a
      @shotInterval = 20
      shot @

  update: (shot, near)->
    switch @status
      when STATUS.READY
        if @respawnCount is 0
          @status = STATUS.ACTIVE
          @pos.x = @base.x + util.randf 1
          @pos.y = @base.y + util.randf 1
          @hp = @fullhp
          @ang = if @team % 2 then 180 else 0
        else
          @respawnCount--
      when STATUS.ACTIVE
        @action @brain.update(@, near), shot, near

        rad = @ang * Math.PI / 180
        @pos.x += @vel * Math.cos rad
        @pos.y += @vel * Math.sin rad
        @vel = @vel * 0.7
        @vel = 0.0 if @vel * @vel < 0.0001

       

        if @hp <= 0
          @status = STATUS.DEAD

      when STATUS.DEAD
        @pos.x = -100
        @pos.y = -100
        @status = STATUS.READY
        @respawnCount = 180

     @scoreboradUpdate()


module.exports = Unit
