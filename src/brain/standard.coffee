util = require '../util'
Brain = require '../brain'
ACTION = require '../actions'

class StandardBrain extends Brain
  constructor: ()->
    super()


  update: (unit)->
    super unit
    acts = []  

    acts.push util.randArray([
      ACTION.MOVE.TOP, 
      ACTION.MOVE.BOTTOM, 
      ACTION.MOVE.LEFT, 
      ACTION.MOVE.RIGHT
    ])

    unless util.rand 5
      acts.push ACTION.ATTACK.AIM

    return acts

module.exports = StandardBrain