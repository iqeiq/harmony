var app = require('app');
var BrowserWindow = require('browser-window');

var mainWindow = null;

app.on('window-all-closed', function() {
  if (process.platform != 'darwin') {
    app.quit();
  }
});

app.on('ready', function() {
  mainWindow = new BrowserWindow({
    width: 640,
    height: 640,
    'node-integration': false,
    'use-content-size': true,
    center: true,
    resizable: false,
    'auto-hide-menu-bar': true
  });

  mainWindow.loadUrl('file://' + __dirname + '/index.html');

  // mainWindow.openDevTools();

  mainWindow.on('closed', function() {
    mainWindow = null;
  });
});