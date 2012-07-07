(function() {
  var EventEmitter, Lookout, fs, path,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  EventEmitter = require('events').EventEmitter;

  path = require('path');

  fs = require('fs');

  Lookout = (function(_super) {

    __extends(Lookout, _super);

    function Lookout(file) {
      this.file = file;
      this.watchedFiles = [];
      this.watchers = [];
      this.watch(file);
    }

    Lookout.prototype.watch = function(path) {
      var stat;
      if (__indexOf.call(this.watchedFiles, path) >= 0) return;
      try {
        stat = fs.statSync(path);
        if (stat.isDirectory()) {
          return this.watchDirectory(path);
        } else if (stat.isFile()) {
          return this.watchFile(path);
        }
      } catch (e) {
        return console.log('Watch fail', e);
      }
    };

    Lookout.prototype.watchFile = function(file) {
      var _this = this;
      fs.watchFile(file, function(curr, prev) {
        if (curr.mtime.getTime() === prev.mtime.getTime()) {
          return _this.emit('remove', file);
        } else {
          return _this.emit('change', file, curr, prev);
        }
      });
      this.emit('add', file, 'file');
      return this.watchedFiles.push(file);
    };

    Lookout.prototype.watchDirectory = function(dir) {
      var child, watcher, _i, _len, _ref,
        _this = this;
      _ref = fs.readdirSync(dir);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        this.watch(path.join(dir, child));
      }
      watcher = fs.watch(dir, function(event, filename) {
        var w;
        if (event === 'rename' && filename) _this.watch(path.join(dir, filename));
        if (event === 'rename' && !filename) {
          if (__indexOf.call(_this.watchers, watcher) >= 0 && !fs.existsSync(dir)) {
            _this.emit('remove', dir, 'dir');
            watcher.close();
            return _this.watchers = (function() {
              var _j, _len2, _ref2, _results;
              _ref2 = this.watchers;
              _results = [];
              for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
                w = _ref2[_j];
                if (w !== watcher) _results.push(w);
              }
              return _results;
            }).call(_this);
          }
        }
      });
      return this.watchers.push(watcher);
    };

    Lookout.prototype.stop = function() {
      var file, watcher, _i, _j, _len, _len2, _ref, _ref2;
      _ref = this.watchedFiles;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        file = _ref[_i];
        fs.unwatchFile(file);
      }
      this.watchedFiles = [];
      _ref2 = this.watchers;
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        watcher = _ref2[_j];
        watcher.close();
      }
      return this.watchers = [];
    };

    return Lookout;

  })(EventEmitter);

  exports.Lookout = Lookout;

}).call(this);
