self.addEventListener('message', function(e) {
  edm = e.data.map;
  queue = e.data.queue;
  dir = e.data.dir;
  sizer = e.data.sizer;

  while(queue.length > 0){
    var x = queue[0].x;
    var y = queue[0].y;
    var v = queue[0].v;
    queue.splice(0, 1);
    dir.forEach(function(d){
      var index = (x + d[0]) + (y + d[1]) * sizer;
      if(edm[index] != 0){ return; }
      edm[index] = v
      if(v > 16){ return; }
      queue.push({
        x: x + d[0],
        y: y + d[1],
        v: v + 1
      });
    });      
  }
      
  self.postMessage(e.data.map);
}, false);