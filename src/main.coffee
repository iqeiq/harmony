'use strict'

View = require './view'
World = require './World'

class Main 
  constructor: ->
    @view = new View
    @world = new World
    
  loop: ->
    requestAnimationFrame => do @loop
    @world.update()
    @view.render @world.render


$ -> do new Main().loop
