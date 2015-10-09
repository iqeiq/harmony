class View
  constructor: ->

    @size = 640
    
    @renderer = PIXI.autoDetectRenderer @size, @size,
        backgroundColor: 0x000000
        antialias: true
        #transparent: true
    $(document.body).append @renderer.view

    img = document.createElement 'img'
    img.src = "content/data/rule.png"
    img.style.position = 'absolute'
    img.style.left = '640px'
    img.style.top = '0px'
    $(document.body).append img
    
    @container = new PIXI.Container

    @stats = new Stats
    @stats.setMode 0  # 0: fps, 1: ms, 2: mb
    @stats.domElement.style.position = 'absolute'
    @stats.domElement.style.right = '0px'
    @stats.domElement.style.top = '0px'
    $(document.body).append @stats.domElement

  render: (updater)->
    @stats.begin()
    updater()
    @renderer.render @container
    @stats.end()


module.exports = View
