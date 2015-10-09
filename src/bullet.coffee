class Bullet
  constructor: (@pos, @size, ang, @vel, @parent)->
    @rad = ang * Math.PI / 180
    @team = @parent.team
    @r = 0
    
  getCollider: ->
    rad45 = Math.PI * 45 / 180
    colls = []
    colls.push
      x: @pos.x # + @size * Math.cos @rad
      y: @pos.y # + @size * Math.sin @rad
    colls.push
      x: @pos.x + @size * Math.cos (@rad + rad45)
      y: @pos.y + @size * Math.sin (@rad + rad45)
    colls.push
      x: @pos.x + @size * Math.cos (@rad - rad45)
      y: @pos.y + @size * Math.sin (@rad - rad45)
    colls

  update: ->
    @pos.x += @vel * Math.cos @rad
    @pos.y += @vel * Math.sin @rad
    @r += @vel

module.exports = Bullet
