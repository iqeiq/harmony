util = require '../util'
Brain = require '../brain'
ACTION = require '../actions'

class StandardBrain extends Brain
  constructor: (@team)->
    super()
    @prevacts = []

  update: (unit)->
    super unit

    if util.rand 10
      return @prevacts

    acts = [] 

    dir = []
    for k in [-1, 0, 1]
      for i in [-1, 0, 1]
        continue if i is 0 and k is 0
        dir.push [i, k]

    {x, y} = unit.pos
    mx = Math.ceil x * @team.mapresolution
    my = Math.ceil y * @team.mapresolution
    cd = @team.coredismap[mx + my * @team.mapsize * @team.mapresolution]
    
    if util.rand 5
      mind = cd
      cand = []
      for d in dir
        index = (mx + d[0]) + (my + d[1]) * @team.mapsize * @team.mapresolution
        dis = @team.coredismap[index]
        continue if dis < 0
        if dis is mind
          cand.push d
        else if dis < mind
          cand = [d]
          mind = dis
    
      if cand.length > 0
        d = util.randArray cand
        switch d[0]
          when -1 then acts.push ACTION.MOVE.LEFT
          when 1 then acts.push ACTION.MOVE.RIGHT
        switch d[1]
          when -1 then acts.push ACTION.MOVE.TOP
          when 1 then acts.push ACTION.MOVE.BOTTOM
    else
      acts.push util.randArray([
        ACTION.MOVE.TOP, 
        ACTION.MOVE.BOTTOM, 
        ACTION.MOVE.LEFT, 
        ACTION.MOVE.RIGHT
      ])
    

    acts.push ACTION.ATTACK.AIM

    return @prevacts = acts

module.exports = StandardBrain