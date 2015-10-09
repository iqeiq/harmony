path = require 'path'
fs = require 'fs'

util = require './util'
Input = require './input'
Unit = require './unit'
Team = require './team'
Bullet = require './bullet'
HumanBrain = require './brain/human'
AttackerBrain = require './brain/attacker'
DefenderBrain = require './brain/defender'
meta = require '../content/data/meta'


class World

  constructor: (@container, @viewsize, @size = 32)->
    @input = new Input
    @size2 = @size * @size
    @gridSize = @viewsize / @size

    @resolution = 2
    @resolution2 = @resolution * @resolution
    @sizer = @size * @resolution
    @sizer2 = @sizer * @sizer
    @gridSizer = @viewsize / @sizerm

    @field = new Uint8Array @size2
    @dismap = new Int32Array @size2


    playerTeam = 1
    @team = []
    base = [{}, {}]
    core = [{}, {}]

    mapstr = fs.readFileSync path.resolve(__dirname, '../content/data/field1.txt'), 'utf8'
    mapstr = mapstr.replace /\r*\n/g, ''
    for v, i in @field
      @field[i] = parseInt mapstr.charAt(i)
      x = i % @size
      y = i / @size | 0
      switch @field[i]
        when 6 then base[0] = {x: x, y: y}
        when 7 then base[1] = {x: x, y: y}
        when 2 then core[0] = {x: x, y: y}
        when 4 then core[1] = {x: x, y: y}

    @team.push new Team(0, base[0], core[0], 0xffa000)
    @team.push new Team(1, base[1], core[1], 0x00ffff)

    for t, i in @team
      t.mapsize = @size
      t.mapresolution = @resolution
      t.coredismap = new Int32Array @sizer2 
      t.coredirmap = new Int32Array @sizer2
      t.enemydismap = new Int32Array @sizer2
      @setCoredismap t, @team[1 - i].core #TODO:
      @setCoredirmap t, @team[1 - i].core
      memberNum = if playerTeam is i then 3 else 4
      defnum = util.rand(memberNum / 2 + 1) + 1
      for k in [0...memberNum]
        if k < defnum
          b = new DefenderBrain t
        else 
          b = new AttackerBrain t
        u = new Unit i, t.base, b
        @addUnit u

    for t, i in @team
      @setEnemydismap t, @team[1 - i].units

    for v, i in @dismap
      @dismap[i] = if [0, 6, 7, 8].some((v)=> @field[i] is v) then 1 else -1

    @gField = @setupField()
    @container.addChild @gField
    
    humanBrain = new HumanBrain @input
    @player = new Unit playerTeam, @team[playerTeam].base, humanBrain
    @addUnit @player

    gStart = @setupStartView()
    @container.addChild gStart

    gPause = @setupPauseView()

    @scene = {}
    @scene.init = =>
      (transit)=>
        if @input.keys['z']
          @container.removeChild gStart
          transit 'main'
    
    @scene.main = =>
      pause = false
      @input.on 'space', =>
        pause = not pause
        if pause
          @container.addChild gPause
        else
          @container.removeChild gPause
      (transit)=>
        return if pause
        @updateUnits()
        @updateBullets()
        @team[0].changePoint -100 if @input.keys['o'] # debug
        @team[1].changePoint -100 if @input.keys['p'] # debug

        result = undefined
        for t, i in @team
          if t.point is 0
            result = if i is playerTeam then false else true
            break

        if result isnt undefined
          @input.offAll()
          gResult = @setupResultView result
          @container.addChild gResult
          transit 'result'
    
    @scene.result = =>
      (transit)->

    @phase = null
    @transit = (next)=> @phase = @scene[next]().bind @, @transit

    @transit 'init'

  setCoredismap: (team, core)->
    cdm = team.coredismap
    queue = []
    for k in [0...@resolution]
      for i in [0...@resolution]
        queue.push
          x: core.x * @resolution + i
          y: core.y * @resolution + k
          v: 1

    dir = []
    for k in [-1, 0, 1]
      for i in [-1, 0, 1]
        continue if i is 0 and k is 0
        dir.push [i, k]

    indexify = (x, y)=>
      rx = x * @resolution
      ry = y * @resolution
      res = []
      for k in [0...@resolution]
        for i in [0...@resolution]
          res.push (rx + i) + (ry + k) * @sizer
      res
    
    for f, i in @field
      continue if [0, 6, 7, 8].some((u)=> f is u)
      x = i % @size
      y = i / @size | 0
      for index in indexify(x, y)
        cdm[index] = -1

    while queue.length > 0
      {x, y, v} = queue[0]
      queue.splice 0, 1
      for d in dir
        index = (x + d[0]) + (y + d[1]) * @sizer
        continue unless cdm[index] is 0
        cdm[index] = v
        queue.push
          x: x + d[0]
          y: y + d[1]
          v: v + 1

    for index in indexify(core.x, core.y)
      cdm[index] = 0

  setCoredirmap: (team, core)->
    cdm = team.coredirmap
    queue = []
    for k in [0...@resolution]
      queue.push
        x: core.x * @resolution + k
        y: core.y * @resolution
        dir: 3
      queue.push
        x: core.x * @resolution + k
        y: core.y * @resolution + @resolution - 1
        dir: 4
      queue.push
        x: core.x * @resolution
        y: core.y * @resolution + k
        dir: 1
      queue.push
        x: core.x * @resolution + @resolution - 1
        y: core.y * @resolution + k
        dir: 2

    indexify = (x, y)=>
      rx = x * @resolution
      ry = y * @resolution
      res = []
      for k in [0...@resolution]
        for i in [0...@resolution]
          res.push (rx + i) + (ry + k) * @sizer
      res
    
    for f, i in @field
      continue if [0, 6, 7, 8].some((u)=> f is u)
      x = i % @size
      y = i / @size | 0
      for index in indexify(x, y)
        cdm[index] = -1

    while queue.length > 0
      {x, y, dir} = queue[0]
      queue.splice 0, 1
      d = [0, 0]
      d[0] = if dir < 3 then (dir - 1) * 2 - 1 else 0
      d[1] = if dir > 2 then (dir - 3) * 2 - 1 else 0
      index = (x + d[0]) + (y + d[1]) * @sizer
      unless cdm[index] is -1
        cdm[index] = dir
        queue.push
          x: x + d[0]
          y: y + d[1]
          dir: dir

    for index in indexify(core.x, core.y)
      cdm[index] = 0


  setEnemydismap: (team, units)->
    for t, i in team.enemydismap
      team.enemydismap[i] = 0

    edm = team.enemydismap
    queue = []
    dir = []
    for k in [-1, 0, 1]
      for i in [-1, 0, 1]
        continue if i is 0 and k is 0
        dir.push [i, k]
    
    indexify = (x, y)=>
      rx = x * @resolution
      ry = y * @resolution
      res = []
      for k in [0...@resolution]
        for i in [0...@resolution]
          res.push (rx + i) + (ry + k) * @sizer
      res
    
    for u in units
      x = Math.ceil(u.i.pos.x * @resolution)
      y = Math.ceil(u.i.pos.y * @resolution) 
      
      queue.push
        x: x
        y: y
        v: 1

    x = Math.ceil(team.core.x * @resolution) + util.rand(8) - 4
    y = Math.ceil(team.core.y * @resolution) + util.rand(8) - 4
    queue.push
      x: x
      y: y
      v: 1
    
    for f, i in @field
      continue if [0, 6, 7, 8].some((u)=> f is u)
      x = i % @size
      y = i / @size | 0
      for index in indexify(x, y)
        edm[index] = -1

    while queue.length > 0
      {x, y, v} = queue[0]
      queue.splice 0, 1
      for d in dir
        index = (x + d[0]) + (y + d[1]) * @sizer
        continue unless edm[index] is 0
        edm[index] = v
        continue if v > 20
        queue.push
          x: x + d[0]
          y: y + d[1]
          v: v + 1

  addUnit: (u)->
    t = u.team
    {x, y} = @team[t].base
    u.pos.x = x + util.randf 1
    u.pos.y = y + util.randf 1
    u.ang = if t % 2 then 180 else 0
    g = @setupUnit u
    @container.addChild g
    @team[t].units.push
      i: u
      g: g

  addBullet: (u)->
    t = u.team
    b = new Bullet {x: u.pos.x, y: u.pos.y}, 0.2, u.shotang, 0.1, u
    g = @setupBullet b
    @container.addChild g
    @team[t].bullets.push
      i: b
      g: g

  hitCheck: (x, y)->
    return -2 if x < 0.5 or y < 0.5
    return -2 if x > @size - 0.5 or y > @size - 0.5
    i = Math.floor(x - 0.5) + @size * Math.floor(y - 0.5)
    rx = x - 0.5 - Math.floor(x - 0.5)
    ry = y - 0.5 - Math.floor(y - 0.5)
    rx = 0 if rx < 0.0001
    ry = 0 if ry < 0.0001
    d = [@dismap[i], @dismap[i + 1], @dismap[i + @size], @dismap[i + @size + 1]]
    f = [@field[i], @field[i + 1], @field[i + @size], @field[i + @size + 1]]
    
    res =  (1 - rx) * (1 - ry) * d[0] + (1 - rx) * ry * d[2] + rx * (1 - ry) * d[1] + rx * ry * d[3]
    _.remove f, (v)-> v is 0
    
    return {d: res, f: _.uniq f} 

  fix: (unit)->
    poss = unit.getCollider()
    for p in poss
      {d, f} = @hitCheck p.x, p.y
      if d < 0
        rad = (unit.ang + 180) * Math.PI / 180
        unit.pos.x -= d * Math.cos rad
        unit.pos.y -= d * Math.sin rad
        unit.vel = 0.0

  setupText: (x, y, str, font, color, stylex, styley)->
    text = new PIXI.Text str,
      font: font
      fill: color
      align: stylex
    switch stylex
      when 'left'
        text.position.x = x
      when 'center'
        text.position.x = x - text.width / 2
      when 'right'
        text.position.x = x - text.width
    switch styley
      when 'top'
        text.position.y = y
      when 'center'
        text.position.y = y - text.height / 2
      when 'bottom'
        text.position.y = y - text.height
    return text

  setupStartView: ->
    g = new PIXI.Graphics
    g.lineStyle 0
      .beginFill 0x333333
      .drawRect 0, 0, @viewsize, @viewsize
      .endFill()
    g.alpha = 0.7

    text = @setupText @viewsize / 2, @viewsize / 2, 'PRESS Z', '24px Papyrus', 0xffffff, 'center', 'center'
    g.addChild text

    col = (util.rand(256) << 16) + (util.rand(256) << 8) + (util.rand(256))
    text2 = @setupText @viewsize / 2, @viewsize / 4, 'harmony', '56px Papyrus', col, 'center', 'center'
    filter = new PIXI.filters.BlurFilter
    filter.blur = 32
    text2.filters = [filter]
    g.addChild text2

    text3 = @setupText @viewsize / 2, @viewsize / 4, 'harmony', '56px Papyrus', 0xffffff, 'center', 'center'
    g.addChild text3

    text4 = @setupText @viewsize, @viewsize, "version: #{meta.version}", '16px Papyrus', 0xffffff, 'right', 'bottom'
    g.addChild text4

    return g

  setupPauseView: ->
    g = new PIXI.Graphics
    g.lineStyle 0
      .beginFill 0x333333
      .drawRect 0, 0, @viewsize, @viewsize
      .endFill()
    g.alpha = 0.7

    text = @setupText @viewsize / 2, @viewsize / 2, 'Pause', '24px Papyrus', 0xffffff, 'center', 'center'
    g.addChild text

    return g

  setupResultView: (isWin)->
    filter = new PIXI.filters.BlurFilter
    filter.blur = 24

    g = new PIXI.Graphics
    g.lineStyle 0
      .beginFill 0x333333
      .drawRect 0, 0, @viewsize, @viewsize
      .endFill()
    g.alpha = 0.7
    col = if isWin then 0xffff00 else 0x00ffff
    str = if isWin then 'You Win' else 'You Lose'
    text = @setupText @viewsize / 2, @viewsize / 2, str, '36px Papyrus', col, 'center', 'center'
    g.addChild text

    text3 = @setupText @viewsize / 2, @viewsize / 2, str, '36px Papyrus', col, 'center', 'center'
    text3.filters = [filter]
    g.addChild text3

    text2 = @setupText @viewsize / 2, @viewsize * 3 / 4, 'PRESS ESC or Reload', '16px Papyrus', 0xffffff, 'center', 'bottom'
    g.addChild text2
    
    return g

  setupField: ->
    g = new PIXI.Graphics
    g2 = new PIXI.Graphics
    filter = new PIXI.filters.BlurFilter
    filter.blur = 7

    draw = (type, width, color)=>
      
      for v, i in @dismap
        x = i % @size
        y = i / @size | 0
        continue if x > @size - 2
        break if y > @size - 2 
        d = [@dismap[i], @dismap[i + 1], @dismap[i + @size], @dismap[i + @size + 1]]
        f = [@field[i], @field[i + 1], @field[i + @size], @field[i + @size + 1]]
      
        continue unless f.some((v)-> v is type)
      
        p = []
        p.push {x: x + 0.5, y: y} if d[0] * d[1] < 0
        p.push {x: x, y: y + 0.5} if d[0] * d[2] < 0
        p.push {x: x + 1.0, y: y + 0.5} if d[1] * d[3] < 0
        p.push {x: x + 0.5, y: y + 1.0} if d[2] * d[3] < 0
        continue unless p.length is 2
        
        g.lineStyle width, color
          .moveTo (p[0].x + 0.5) * @gridSize, (p[0].y + 0.5) * @gridSize
          .lineTo (p[1].x + 0.5) * @gridSize, (p[1].y + 0.5) * @gridSize

        g2.lineStyle width * 2, color
          .moveTo (p[0].x + 0.5) * @gridSize, (p[0].y + 0.5) * @gridSize
          .lineTo (p[1].x + 0.5) * @gridSize, (p[1].y + 0.5) * @gridSize

    draw 1, 2, 0x00ff7f
    draw 2, 2, 0xff7f00
    draw 3, 2, 0xff3000
    draw 4, 2, 0x00a0ff
    draw 5, 2, 0x0050ff

    filter2 = new PIXI.filters.BlurFilter
    filter2.blur = 32

    for t in @team
      str = "#{t.point}"
      col = 0xffffff
      x = (t.base.x + 0.5) * @gridSize
      y = (t.base.y + 0.5) * @gridSize
      t.scoreborad = @setupText x, y, str, '36px Papyrus', col, 'center', 'center'
      t.scoreborad2 = @setupText x, y, str, '36px Papyrus', t.color, 'center', 'center'
      t.scoreborad2.filters = [filter2]
      t.scoreborad.alpha = 0.7
      
      t.scoreboradUpdate = do =>
        gs = @gridSize
        ->
          x = (@base.x + 0.5) * gs
          y = (@base.y + 0.5) * gs
          @scoreborad.text = "#{@point}" 
          @scoreborad2.text = @scoreborad.text
          @scoreborad.position.x = x - @scoreborad.width / 2
          @scoreborad.position.y = y - @scoreborad.height / 2
          @scoreborad2.position  = @scoreborad.position
      
      g.addChild t.scoreborad2
      g.addChild t.scoreborad

    g.blendMode = PIXI.BLEND_MODES.ADD
    g.alpha = 0.7
    #g2.alpha = 0.5
    g2.filters = [filter]

    g.addChild g2

    ###
    for t, ti in @team
      continue unless ti is 1
      for d, i in t.enemydismap #t.coredirmap
        continue unless d > 0
        x = i % @sizer
        y = (i / @sizer) | 0
        tx = (x + 0.5) * @gridSizer
        ty = (y + 0.5) * @gridSizer
        text = @setupText tx, ty, "#{d}", '8px', 0xffffff, 'center', 'center'
        g.addChild text
    ###

    return g

  setupBullet: (b)->
    g = new PIXI.Graphics
    
    p0x = b.pos.x * @gridSize
    p0y = b.pos.y * @gridSize
    size = b.size * @gridSize

    g.lineStyle 1, @team[b.team].color
      .drawCircle 0, 0, size

    g.position.x = p0x
    g.position.y = p0y 

    return g

  setupUnit: (unit)->
    g = new PIXI.Graphics
    
    p0x = unit.pos.x * @gridSize
    p0y = unit.pos.y * @gridSize
    size = unit.size * @gridSize

    p1x = size
    p1y = 0

    rad = -150 * Math.PI / 180
    p2x = size * Math.cos rad
    p2y = size * Math.sin rad

    rad = 150 * Math.PI / 180
    p3x = size * Math.cos rad
    p3y = size * Math.sin rad
    
    g.lineStyle 2, @team[unit.team].color
      .moveTo p1x, p1y
      .lineTo p2x, p2y
      .lineTo 0, 0
      .lineTo p3x, p3y
      .lineTo p1x, p1y

    unit.scoreborad = @setupText p0x + size * 1.4, p0y - size * 1.4, "#{unit.hp}", '14px Papyrus', 0xffffff, 'center', 'center'
    unit.scoreboradUpdate = do =>
      gs = @gridSize
      ->
        p0x = @pos.x * gs
        p0y = @pos.y * gs
        size = @size * gs
        @scoreborad.text = "#{@hp}"
        @scoreborad.position.x = p0x + size * 1.4
        @scoreborad.position.y = p0y - size * 1.4

    @container.addChild unit.scoreborad
    g.position.x = p0x
    g.position.y = p0y 
    g.rotation = unit.ang * Math.PI / 180

    return g

  getNear: (pos, team, limit)->
    ang = undefined
    for u in team.units
      {x, y} = u.i.pos
      r2 = Math.pow(pos.x - x, 2) + Math.pow(pos.y - y, 2) 
      if r2 < limit * limit
        rad = Math.atan2 y - pos.y, x - pos.x
        ang = rad * 180 / Math.PI
    ang

  updateUnits: ->
    for t, ti in @team
      unless util.rand 8
        @setEnemydismap t, @team[1 - ti].units
      for u in t.units
        u.i.update (v)=>
          @addBullet v
        , (pos, limit)=>
          @getNear pos, @team[1 - ti], limit

        @fix u.i

        for t in @team
          continue if u.i.team is t.id 
          p1 = u.i.pos
          r1 = u.i.size * 3 / 4
          for b in t.bullets
            p2 = b.i.pos
            r2 = b.i.size
            if Math.pow(p1.x - p2.x, 2) + Math.pow(p1.y - p2.y, 2) < Math.pow(r1 + r2, 2)
              b.i.removeflag = true
              u.i.hp--
              u.i.scoreboradUpdate()

        u.g.position.x = u.i.pos.x * @gridSize
        u.g.position.y = u.i.pos.y * @gridSize
        u.g.rotation = u.i.shotang * Math.PI / 180

  updateBullets: ->
    for t in @team
      removeList = []
      for b, i in t.bullets
        b.i.update()
        poss = b.i.getCollider()
        for p in poss
          {d, f} = @hitCheck p.x, p.y
          if d < 0
            b.i.removeflag = true
            for type in f
              switch type
                when 2
                  break if b.i.team is 0
                  @team[0].changePoint -1
                when 4
                  break if b.i.team is 1
                  @team[1].changePoint -1

        b.g.position.x = b.i.pos.x * @gridSize
        b.g.position.y = b.i.pos.y * @gridSize
        b.g.rotation = b.i.rad

        if b.i.removeflag
          removeList.push i
          @container.removeChild b.g 

      _.remove t.bullets, (v, k)-> removeList.some((u)-> u is k)


  update: ->
    location.reload() if @input.keys['esc']
    @phase()

module.exports = World
