class Utility
  @rand = (n)->
    Math.floor Math.random() * n

  @randf = (n)->
    Math.random() * n

  @randRange = (min, max)->
    Math.floor(Math.random() * (max - min + 1)) + min
  
  @randArray = (arr)->
    arr[Math.floor Math.random() * arr.length]


module.exports = Utility