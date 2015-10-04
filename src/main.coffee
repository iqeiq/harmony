'use strict'

View = require './view'
World = require './World'

class Main 
  constructor: ->
    @view = new View
    @world = new World @view.container, @view.size
    
  loop: ->
    requestAnimationFrame => @loop()
    @view.render => @world.update()

$ -> do new Main().loop
