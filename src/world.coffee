path = require 'path'
fs = require 'fs'

util = require './util'
Input = require './input'
Unit = require './unit'
Team = require './team'
HumanBrain = require './brain/human'
StandardBrain = require './brain/standard'


class World

  constructor: (@container, @viewsize, @size = 32)->
    @input = new Input
    @size2 = @size * @size
    @gridSize = @viewsize / @size

    @field = new Uint8Array @size2
    @dismap = new Int32Array @size2
    @plInfmap = new Float32Array @size2
    @enInfmap = new Float32Array @size2

    playerTeam = 1
    @team = []
    base = [{}, {}]

    mapstr = fs.readFileSync path.resolve(__dirname, '../content/data/field1.txt'), 'utf8'
    mapstr = mapstr.replace /\r*\n/g, ''
    for v, i in @field
      @field[i] = parseInt mapstr.charAt(i)
      x = i % @size
      y = i / @size | 0
      switch @field[i]
        when 6 then base[0] = {x: x, y: y}
        when 7 then base[1] = {x: x, y: y}

    @team.push new Team(0, base[0], 0xffa000)
    @team.push new Team(1, base[1], 0x00ffff)

    for v, i in @dismap
      @dismap[i] = if [0, 6, 7, 8].some((v)=> @field[i] is v) then 1 else -1

    @gField = @setupField()
    @container.addChild @gField
    
    humanBrain = new HumanBrain @input
    @player = new Unit playerTeam, humanBrain
    @addUnit @player

    for t, i in @team
      memberNum = if playerTeam is i then 3 else 4
      for k in [0...memberNum]
        b = new StandardBrain
        u = new Unit i, b
        @addUnit u


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

  hitCheck: (x, y)->
    return -2 if x < 0.5 or y < 0.5
    return -2 if x > @size - 0.5 or y > @size - 0.5
    index = Math.floor(x - 0.5) + @size * Math.floor(y - 0.5)
    rx = x - 0.5 - Math.floor(x - 0.5)
    ry = y - 0.5 - Math.floor(y - 0.5)
    rx = 0 if rx < 0.0001
    ry = 0 if ry < 0.0001
    d = [
      @dismap[index],
      @dismap[index + 1],
      @dismap[index + @size],
      @dismap[index + @size + 1]
    ]
    return (1 - rx) * (1 - ry) * d[0] + (1 - rx) * ry * d[2] + rx * (1 - ry) * d[1] + rx * ry * d[3]
    
  fix: (unit)->
    poss = unit.getCollider()
    for p in poss
      d = @hitCheck p.x, p.y
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
      when 'center'
        text.position.x = x - text.width / 2
      when 'right'
        text.position.x = x - text.width
    switch styley
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

    for t in @team
      str = "#{t.point}"
      col = 0xffffff
      x = (t.base.x + 0.5) * @gridSize
      y = (t.base.y + 0.5) * @gridSize
      t.scoreborad = @setupText x, y, str, '36px Papyrus', col, 'center', 'center'
      t.scoreborad.alpha = 0.7
      t.scoreboradUpdate = do =>
        gs = @gridSize
        ->
          x = (@base.x + 0.5) * gs
          y = (@base.y + 0.5) * gs
          @scoreborad.position.x = x - @scoreborad.width / 2
          @scoreborad.position.y = y - @scoreborad.height / 2
        
      g.addChild t.scoreborad

    g.blendMode = PIXI.BLEND_MODES.ADD
    g.alpha = 0.7
    g2.alpha = 0.3
    g2.filters = [filter]

    g.addChild g2

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

    g.position.x = p0x
    g.position.y = p0y 

    return g

  updateUnits: ->
    for t in @team
      for u in t.units
        u.i.update()
        @fix u.i
        u.g.position.x = u.i.pos.x * @gridSize
        u.g.position.y = u.i.pos.y * @gridSize
        u.g.rotation = u.i.ang * Math.PI / 180

  update: ->
    location.reload() if @input.keys['esc']
    @phase()

module.exports = World
