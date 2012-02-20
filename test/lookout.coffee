{clean, rm, touch, mkdir, fix} = require './support/file'
{Lookout} = require '../src/lookout.coffee'
fs = require 'fs'

WAIT_TIME = 1000

describe 'Lookout', ->
  beforeEach (done)->
    clean done

  describe 'Test Harness', ->
    beforeEach (done) ->
      touch "target.file", done

    it "should have test file in place", (done) ->
      fs.stat fix("target.file"), done

    it "should not have bad files", ->
      -> fs.statSync fix "bad.file"
      .should.throw()

  describe 'watching a file', ->
    lookout = null

    beforeEach (done) ->
      touch 'target.file', () ->
        setTimeout ->
          lookout = new Lookout fix('target.file')
          done()
        , WAIT_TIME

    afterEach ->
      lookout?.stop()

    it 'should detect changes to the file', (done) ->
      lookout.on 'change', (path, curr, prev) ->
        path.should.equal fix('target.file')
        curr.mtime.should.be.ok
        prev.mtime.should.be.ok
        done()
      touch 'target.file'

    it 'should detect deletion of the file', (done) ->
      lookout.on 'remove', (path) ->
        done()
      rm 'target.file'

  describe 'watching a directory', ->
    lookout = null

    beforeEach (done) ->
      mkdir 'dir', ->
        touch 'dir/foo.file', ->
          touch 'dir/bar.file', ->
            setTimeout ->
              lookout = new Lookout fix('dir/')
              done()
            , WAIT_TIME

    afterEach ->
      lookout?.stop()

    it 'should detect changes to direct children', (done) ->
      lookout.on 'change', (path, curr, prev)  ->
        path.should.equal fix('dir/foo.file')
        done()
      touch 'dir/foo.file'

    it 'should detect removal of direct children', (done) ->
      lookout.on 'remove', (path)  ->
        path.should.equal fix('dir/foo.file')
        done()
      rm 'dir/foo.file'

    it 'should detect the creation of new files', (done) ->
      lookout.on 'add', (path) ->
        if path is fix('dir/new.file')
          done()
      touch 'dir/new.file'

    it 'should detect deletion of itself', (done) ->
      lookout.on 'remove', (path) ->
        if path is fix('dir/')
          done()
      rm 'dir'

  describe 'watching a nested directory', ->
    lookout = null

    beforeEach (done) ->
      mkdir 'd1', ->
        mkdir 'd1/d2', ->
          touch 'd1/d2/foo.file', ->
            setTimeout ->
              lookout = new Lookout fix('d1')
              done()
            , WAIT_TIME

    afterEach ->
      lookout.stop()

    it 'should detect changes on nested files', (done) ->
      lookout.on 'change', (path, curr, prev) ->
        path.should.be.equal fix('d1/d2/foo.file')
        done()
      touch 'd1/d2/foo.file'

    it 'should detect a new file nested in a new directory', (done) ->
      lookout.on 'add', (path, curr, prev) ->
        console.log path
        if path is fix('d1/d3/bar.file')
          done()
      mkdir 'd1/d3', ->
        setTimeout (-> touch 'd1/d3/bar.file'), 1000




