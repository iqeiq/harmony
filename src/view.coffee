class View
  constructor: ->
    @canvas = document.getElementById 'view'
    @backcanvas = document.createElement 'canvas'
    @backcanvas.style.visibility = 'hidden'

    @ctx = @canvas.getContext '2d'
    @backctx = @backcanvas.getContext '2d'
    
    @update()
    
    $(window).resize =>
      @update()

    @stats = new Stats
    @stats.setMode 0  # 0: fps, 1: ms, 2: mb
    @stats.domElement.style.position = 'absolute'
    @stats.domElement.style.left = '0px'
    @stats.domElement.style.top = '0px'
    $(document.body).append @stats.domElement
    
  update: ->
    width = window.innerWidth
    height = window.innerHeight
    @viewSize = Math.min width, height
    @canvas.width = @viewSize
    @canvas.height = @viewSize
    @backcanvas.width = @viewSize
    @backcanvas.height = @viewSize

  render: (updater)->
    @stats.begin()
    @backctx.clearRect 0, 0, @backcanvas.width, @backcanvas.height
    @backctx.fillStyle = "black"
    @backctx.fillRect 0, 0, @viewSize, @viewSize
    @backctx.fill()
    updater @backctx, @viewSize
    @ctx.drawImage @backcanvas, 0, 0
    @stats.end()


module.exports = View
