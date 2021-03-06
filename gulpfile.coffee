coffee = require "gulp-coffee"
concat = require "gulp-concat"
less = require "gulp-less"
plumber = require "gulp-plumber"
gulp = require "gulp"
path = require "path"
streamqueue = require "streamqueue"
uglify = require "gulp-uglify"
rename = require "gulp-rename"

BOWER_PATH = "bower_components/"
SRC_PATH = "_src/"
DEST_PATH = "assets/"

LESS_FILES = [
  "#{SRC_PATH}/less/style.less"
]

gulp.task "css", ->
  gulp.src LESS_FILES
    .pipe plumber()
    .pipe less
      paths: [
        path.resolve(__dirname, "#{SRC_PATH}/less")
        path.resolve(__dirname, "#{BOWER_PATH}/bootstrap/less")
      ]
      compress: true
    .pipe gulp.dest("#{DEST_PATH}/css")


COFFEE_FILES = [
  "#{SRC_PATH}/coffee/app*.coffee"
]

FRAMEWORK_FILES = [
  "#{BOWER_PATH}/jquery/dist/jquery.js"
  "#{BOWER_PATH}/js-yaml/js-yaml.js"
  "#{BOWER_PATH}/ace-builds/src-noconflict/ace.js"
  "#{BOWER_PATH}/angular/angular.js"
  "#{BOWER_PATH}/angular-route/angular-route.js"
  "#{BOWER_PATH}/angular-cookies/angular-cookies.js"
  "#{BOWER_PATH}/angular-animate/angular-animate.js"
  "#{BOWER_PATH}/angularLocalStorage/src/angularLocalStorage.js"

  "#{BOWER_PATH}/angular-unsavedChanges/dist/unsavedChanges.js"
  "#{BOWER_PATH}/octokit/octokit.js"
  "#{SRC_PATH}/js/mode-markdown.js"
  "#{SRC_PATH}/js/ext-settings_menu.js"
  "#{SRC_PATH}/js/theme-tomorrow-markdown.js"
  "#{SRC_PATH}/js/filereader.js"
]

JS_FILES = [
  "#{DEST_PATH}/js/application.js"
  "#{DEST_PATH}/js/framework.js"
]

gulp.task "js", ->
  appQueue = streamqueue(objectMode: true)

  appQueue.queue(
    gulp.src COFFEE_FILES
      .pipe plumber()
      .pipe coffee(bare:true)
  )

  appQueue.done()
    .pipe plumber()
    .pipe concat "application.js"
    .pipe gulp.dest("#{DEST_PATH}/js")


gulp.task "framework", ->
  gulp.src FRAMEWORK_FILES
    .pipe plumber()
    .pipe concat "framework.js"
    .pipe gulp.dest("#{DEST_PATH}/js")

gulp.task "minify", ["framework", "js"], ->
  gulp.src JS_FILES
    .pipe plumber()
    .pipe rename (path)->
      path.basename += ".min"
      return
    .pipe uglify(mangle: false)
    .pipe gulp.dest("#{DEST_PATH}/js")

gulp.task "watch", ["css", "js"], ->
  gulp.watch COFFEE_FILES, ["js"]
  gulp.watch FRAMEWORK_FILES, ["framework"]
  gulp.watch "#{SRC_PATH}/less/*.less", ["css"]

FILES =[
  "#{SRC_PATH}/img/*"
]

gulp.task "copy", ->
  gulp.src FILES
    .pipe gulp.dest("#{DEST_PATH}/img")

  gulp.src "#{BOWER_PATH}/ace-builds/src-min-noconflict/**/*.js"
    .pipe gulp.dest("#{DEST_PATH}/js/ace/")

gulp.task "default", ["css", "js", "framework", "copy", "watch"]

gulp.task "production", ["css", "js", "framework", "minify", "copy"]