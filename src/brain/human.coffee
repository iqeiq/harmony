Brain = require '../brain'
ACTION = require '../actions'

class HumanBrain extends Brain
  constructor: (@input)->
    super()


  update: (unit)->
    super unit
    acts = []  

    if @input.keys['up']
      acts.push ACTION.MOVE.TOP
    if @input.keys['down']
      acts.push ACTION.MOVE.BOTTOM
    if @input.keys['right']
      acts.push ACTION.MOVE.RIGHT
    if @input.keys['left']
      acts.push ACTION.MOVE.LEFT
    if @input.keys['x']
      acts.push ACTION.HARMONY.MASTER
    if @input.keys['z'] and @input.keys['shift']
      acts.push ACTION.ATTACK.AIM
    else if @input.keys['z']
      acts.push ACTION.ATTACK.FOWARD
    
    
    acts

module.exports = HumanBrain