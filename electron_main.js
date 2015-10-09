var app = require('app');
var BrowserWindow = require('browser-window');
var fs = require('fs');
var https = require('https');
var express = require('express');
var expapp = express();

expapp.use(express.static(__dirname + '/'));

expapp.listen(7077, function(){

var mainWindow = null;

app.on('window-all-closed', function() {
  if (process.platform != 'darwin') {
    app.quit();
  }
});

app.on('ready', function() {
  if(process.argv[1] == 'update'){
    mainWindow = new BrowserWindow({
      width: 320,
      height: 320,
      'node-integration': false,
      'use-content-size': true,
      center: true,
      resizable: false,
      'auto-hide-menu-bar': true
    });
    mainWindow.loadUrl('file://' + __dirname + '/update.html');
    
    console.log("start update.");
    var url = "https://dl.dropboxusercontent.com/s/91f6cojy5nvhp7b/harmony.zip"
    var outFile = fs.createWriteStream('./harmony.zip');
    var req = https.get(url, function(res){
      res.pipe(outFile);
      res.on('end', function(){
        outFile.close();
        console.log("done!");
        app.quit();
      }); 
    });
    req.on('error', function(err){
      console.log('Error: ', err);
      app.quit();
    });
  } else {
    mainWindow = new BrowserWindow({
      width: 640 + 480,
      height: 640,
      'node-integration': false,
      'use-content-size': true,
      center: true,
      resizable: false,
      'auto-hide-menu-bar': true
    });
    //mainWindow.loadUrl('file://' + __dirname + '/index.html');
    mainWindow.loadUrl('http://127.0.0.1:7077');
    //mainWindow.openDevTools();
  }

  mainWindow.on('closed', function() {
    mainWindow = null;
  });
});

});