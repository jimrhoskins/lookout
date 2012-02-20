{EventEmitter} = require 'events'
path = require 'path'
fs = require 'fs'

class Lookout extends EventEmitter
  constructor: (file) ->
    @file = file
    @watchedFiles = []
    @watchers = []
    @watch file

  watch: (path) ->
    try
      stat = fs.statSync path
      if stat.isDirectory()
        @watchDirectory path
      else if stat.isFile()
        @watchFile path
    catch e
      console.log 'Watch fail', e
      #nothing

  watchFile: (file) ->
    fs.watchFile file, (curr, prev) =>
      if curr.mtime.getTime() is prev.mtime.getTime()
        @emit 'remove', file
      else
        @emit 'change', file, curr, prev

    @emit 'add', file, 'file'
    @watchedFiles.push file

  watchDirectory: (dir) ->
    for child in fs.readdirSync dir
      @watch path.join(dir, child)

    watcher = fs.watch dir, (event, filename) =>
      if event is 'rename' and filename
        file = path.join(dir, filename)
        unless file in @watchedFiles
          @watch file

      if event is 'rename' and not filename
        if watcher in @watchers
          unless path.existsSync dir 
            @emit 'remove', dir, 'dir'
            watcher.close()
            @watchers = (w for w in @watchers when w isnt watcher)

    console.log 'watching dir', dir
    @watchers.push watcher

  stop: ->
    for file in @watchedFiles
      fs.unwatchFile file
    @watchedFiles = []
    for watcher in @watchers 
      watcher.close()
    @watchers = []


exports.Lookout = Lookout
