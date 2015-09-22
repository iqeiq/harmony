class View
  constructor: ->
    @canvas = document.getElementById 'view'
    @ctx = @canvas.getContext '2d'
    @update()
    
    $(window).resize =>
      @update()

    ###
    @stats = new Stats
    @stats.setMode 0  # 0: fps, 1: ms, 2: mb
    @stats.domElement.style.position = 'absolute'
    @stats.domElement.style.left = '0px'
    @stats.domElement.style.top = '0px'
    $(document.body).append @stats.domElement
    ###

  update: ->
    width = window.innerWidth
    height = window.innerHeight
    @viewSize = Math.min width, height
    @canvas.width = @viewSize
    @canvas.height = @viewSize

  render: (updater)->
    #@stats.begin()
    @ctx.clearRect 0, 0, @canvas.width, @canvas.height
    @ctx.fillStyle = "black"
    @ctx.fillRect 0, 0, @viewSize, @viewSize
    updater @ctx
    #@stats.end()


module.exports = View
