path = require 'path'
fs = require 'fs'

TYPE = require './types'
util = require './util'
Input = require './input'
Unit = require './unit'
HumanBrain = require './brain/human'

class World

  constructor: (@size = 32)->
    @size2 = @size * @size

    @field = new Uint8Array @size2
    @dismap = new Int32Array @size2
    @plInfmap = new Float32Array @size2
    @enInfmap = new Float32Array @size2

    mapstr = fs.readFileSync path.resolve(__dirname, '../content/data/field1.txt'), 'utf8'
    mapstr = mapstr.replace /\r*\n/g, ''
    for v, i in @field
      @field[i] = parseInt mapstr.charAt(i)

    for v, i in @dismap
      @dismap[i] = if @field[i] is 0 then 1 else -1

    @input = new Input
    humanBrain = new HumanBrain @input
    @player = new Unit @size / 2, @size / 2, TYPE.UNIT.PLAYER, humanBrain

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

    
  drawGrid: (ctx, viewSize)->
    ctx.strokeStyle = 'rgb(92, 92, 92)'
    
    for x in [0...@size]
      ctx.beginPath()
      ctx.moveTo x * @gridSize, 0
      ctx.lineTo x * @gridSize, viewSize
      ctx.stroke()

    for y in [0...@size]
      ctx.beginPath()
      ctx.moveTo 0, y * @gridSize
      ctx.lineTo viewSize, y * @gridSize
      ctx.stroke()

  drawField: (ctx)->
    
    draw = (type, color)=>
      ctx.strokeStyle = color
      ctx.beginPath()

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
      
        ctx.moveTo (p[0].x + 0.5) * @gridSize, (p[0].y + 0.5) * @gridSize
        ctx.lineTo (p[1].x + 0.5) * @gridSize, (p[1].y + 0.5) * @gridSize

      ctx.stroke()

    draw 1, 'rgb(0, 255, 128)'
    draw 2, 'rgb(255, 128, 0)'
    draw 3, 'rgb(255, 48, 0)'
    draw 4, 'rgb(0, 160, 255)'
    draw 5, 'rgb(0, 92, 255)'

  drawUnit: (ctx, unit)->
    ctx.strokeStyle = 'rgb(0, 255, 255)'
    ctx.fillStyle = 'rgb(0, 0, 0)'
    ctx.beginPath()
    ctx.lineWidth = 2

    
    p0x = unit.pos.x * @gridSize
    p0y = unit.pos.y * @gridSize
    size = unit.size * @gridSize

    rad = unit.ang * Math.PI / 180
    p1x = p0x + size * Math.cos rad
    p1y = p0y + size * Math.sin rad

    #console.log @getDistance(unit.pos.x + unit.size * Math.cos(rad), unit.pos.y + unit.size * Math.sin(rad))

    rad = (unit.ang - 150) * Math.PI / 180
    p2x = p0x + size * Math.cos rad
    p2y = p0y + size * Math.sin rad

    rad = (unit.ang + 150) * Math.PI / 180
    p3x = p0x + size * Math.cos rad
    p3y = p0y + size * Math.sin rad
    
    rad = unit.ang * Math.PI / 180
    ctx.moveTo p1x, p1y
    ctx.lineTo p2x, p2y
    ctx.lineTo p0x, p0y
    ctx.lineTo p3x, p3y
    ctx.lineTo p1x, p1y

    ctx.fill()
    ctx.stroke()

    

  update: ->
    @player.update()
    @fix @player


  render: (ctx, viewSize)=>
    @gridSize = viewSize / @size
    @drawField ctx
    @drawUnit ctx, @player

module.exports = World
