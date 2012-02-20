path = require 'path'
{spawn} = require 'child_process'

ROOT = path.normalize "#{__dirname}/../fixture"

fix = (file) ->
  path.join ROOT, file

touch = (file, callback) ->
  spawn('touch', [fix(file)]).on 'exit', (code) ->
    callback() if callback?

mkdir = (path, callback) ->
  p = spawn('mkdir', [fix(path)])
  p.stderr.pipe process.stderr
  p.on 'exit', (code) ->
    callback() if callback?

clean = (callback) ->
  rm ".", (err) ->
    mkdir '.', (err) ->
      callback() if callback?

rm = (path, callback) ->
  p = spawn('rm', ['-r', fix(path)])
  p.stderr.pipe process.stderr
  p.on 'exit', (code) ->
    callback() if callback?

module.exports = {
  touch
  mkdir
  rm
  clean
  fix
}
