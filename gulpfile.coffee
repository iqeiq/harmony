'use strict'

gulp = require 'gulp'
browserify = require 'browserify'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'
uglify = require 'gulp-uglify'
concat = require 'gulp-concat'
gutil = require 'gulp-util'
sourcemaps = require 'gulp-sourcemaps'
mainBowerFiles= require 'main-bower-files'
watchify = require 'watchify'
assign = require 'lodash.assign'
exists = require('path-exists').sync
packager = require 'electron-packager'

gulp.task 'copy', ['bower-build', 'build'], ->
  gulp.src ['index.html', 'electron_main.js', 'package.json', 'content/js/*.js', 'content/css/**', 'content/data/**'],
    base: '.'
  .pipe gulp.dest('temp')

gulp.task 'pack', ['copy'], (done)->
  packager
    dir: 'temp'
    out: 'build'
    name: 'harmony'
    arch: 'all'
    platform: 'all'
    version: '0.33.6'
    overwrite: true
    asar: true
  , (err, path)-> done()

watchify.args.fullPaths = false
opts = assign {}, watchify.args,
  entries: ['./src/main.coffee']
  extensions: ['.coffee', '.js']
  debug: true
  transform: ['coffeeify', 'brfs']

b = watchify browserify opts

gulp.task 'bower-build', ->
  files = mainBowerFiles
    debugging: true
    checkExistence: true  
  .map (path)->
    newPath = path.replace /.([^.]+)$/g, '.min.$1'
    if exists newPath then newPath else path
  gulp.src files
    .pipe concat 'bower_components.js'
    .pipe gulp.dest 'content/js'

###
gulp.task 'lib-build', ->
  gulp.src 'content/js/lib/*'
    .pipe concat 'libs.js'
    .pipe uglify
      preserveComments: 'some'
    .pipe gulp.dest 'content/js'
###

build = ->
  b
    .bundle()
    .on 'error', gutil.log.bind(gutil, 'Browserify Error')
    .pipe source 'bundle.js'
    .pipe buffer()
    .pipe sourcemaps.init
      loadMaps: true
    .pipe uglify
      preserveComments: 'some'
    .pipe sourcemaps.write './',
      addComment: true
      sourceRoot: './src'
    .pipe gulp.dest './content/js'


gulp.task 'build', build
b.on 'update', build
b.on 'log', gutil.log

gulp.task 'default', ['bower-build', 'build'], ->
  