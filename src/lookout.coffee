{EventEmitter} = require 'events'
path = require 'path'
fs = require 'fs'

# Watching for changes on existing files as well as creation
# of new files requires the use of both fs.watchFile and 
# fs.watch
#
# fs.watch can watch a directory, but provides less event 
# information. fs.watchFile can only watch existing files
# and provides file stats

class Lookout extends EventEmitter
  constructor: (file) ->
    @file = file
    @watchedFiles = []
    @watchers = []
    @watch file

  watch: (path) ->
    return if path in @watchedFiles
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
      # When mod times are the same, the file has been deleted
      # TODO find cases where mtimes equal, but not deleted
      if curr.mtime.getTime() is prev.mtime.getTime()
        @emit 'remove', file
      else
        @emit 'change', file, curr, prev

    @emit 'add', file, 'file'
    @watchedFiles.push file

  watchDirectory: (dir) ->
    # Watch existing child dirs/files
    for child in fs.readdirSync dir
      @watch path.join(dir, child)

    # Wactch for new file additions, or removal of self
    watcher = fs.watch dir, (event, filename) =>
      if event is 'rename' and filename
        @watch path.join(dir, filename)

      if event is 'rename' and not filename
        if watcher in @watchers and not path.existsSync dir
          @emit 'remove', dir, 'dir'
          watcher.close()
          @watchers = (w for w in @watchers when w isnt watcher)

    @watchers.push watcher

  stop: ->
    for file in @watchedFiles
      fs.unwatchFile file
    @watchedFiles = []

    for watcher in @watchers 
      watcher.close()
    @watchers = []


exports.Lookout = Lookout
