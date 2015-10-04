class Input
  constructor: (@domElement = document)->
    @keys = {}
    @listener = {}

    @keyMap =
      8: 'backspace'
      13: 'enter'
      16: 'shift'
      17: 'ctrl'
      18: 'alt'
      27: 'esc'
      32: 'space'
      37: 'left'
      38: 'up'
      39: 'right'
      40: 'down'

    mapper = (keycode, status)=>
      key: @keyMap[keycode] or String.fromCharCode(keycode).toLowerCase()
      status: status

    keydown = Bacon.fromEventTarget(@domElement, 'keydown').map (e)=> mapper.call @, e.keyCode, true
    keyup = Bacon.fromEventTarget(@domElement, 'keyup').map (e)=> mapper.call @, e.keyCode, false
    keydown.merge(keyup).filter (e)->
      code = e.key.charCodeAt 0
      47 < code < 58 or 96 < code < 123
    .onValue (e)=>
      @keys[e.key] = e.status
      return unless e.status 
      @listener[e.key]?.forEach (v)-> do v

    buttons = [1, 2]
    
    mouseEvent = (type)=>
      listener = {}
      buttons.forEach (e)-> listener[e] = []
      Bacon.fromEventTarget @domElement, type
        .filter (e)-> e.button in buttons
        .onValue (e)-> listener[e.button].forEach (v)-> v e.clientX, e.clientY
      [ 
        (btn, cb)-> listener[btn]?.push cb,
        (btn, cb)-> _.remove listener[btn], (v)-> if cb? then v is cb else true
      ]

    [@onMouseDown, @offMouseDown] = mouseEvent 'mousedown'
    [@onMouseUp, @offMouseUp] = mouseEvent 'mouseup'
    [@onDoubleClick, @offDoubleClick] = _.transform mouseEvent('dblclick'), (res, e)-> res.push e.bind @, 1

    [@onMouseMove, @offMouseMove] = do =>
      listener = {}
      active = {}
      buttons.forEach (e)-> 
        active[e] = false
        listener[e] = []
      md = Bacon.fromEventTarget(@domElement, 'mousedown').map (e)-> [e.button, true]
      mu = Bacon.fromEventTarget(@domElement, 'mouseup').map (e)-> [e.button, false]
      md.merge(mu).onValue (e)-> active[e[0]] = e[1] if active[e[0]]?
      Bacon.fromEventTarget(@domElement, 'mousemove').onValue (e)->
        for own k, v of listener
          v.forEach (u)-> u e.clientX, e.clientY if active[k] 
      [
        (btn, cb)-> listener[btn]?.push cb,
        (btn, cb)-> _.remove listener[btn], (v)-> if cb? then v is cb else true
      ]

    @offAll = =>
      buttons.forEach (v)=>
        @offMouseDown v
        @offMouseUp v
        @offMouseMove v
      @offDoubleClick()
      @listener = {}
        

  on: (key, cb)->
    return @listener[key].push cb if @listener[key]
    @listener[key] = [cb]

  off: (key, cb)->
    _.remove @listener[key], (v)-> v is cb


module.exports = Input