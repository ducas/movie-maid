const path = require('path');
const fs = require('fs');
const glob = require('glob');
const mkdirp = require('mkdirp');
const unique = require('array-unique');
const commandLineArgs = require('command-line-args');
 
const optionDefinitions = [
  { name: 'verbose', alias: 'v', type: Boolean },
  { name: 'src', alias: 's', type: String },
  { name: 'dest', alias: 'd', type: String },
  { name: 'preserve', alias: 'p', type: Boolean },
  { name: 'whatif', alias: 'w', type: Boolean }
];

const extensions = [ 'mp4', 'mkv', 'avi' ];

const options = commandLineArgs(optionDefinitions);

for (var i = 0; i < extensions.length; i++) {
  var ext = extensions[i];

  if (options.verbose) {
    console.log('Searching: ' + options.src + '/**/*.' + ext);
  }

  glob(options.src + '/**/*.' + ext, function (err, res) {
    if (err) {
      console.log('Error', err);
      return;
    } else {
      if (res.length === 0) {
        if (options.verbose) { console.log('No results.'); }
        return;
      }

      if (options.verbose) { 
         console.log('Found:');
         console.log(res);
      }

      var directories = res.map(r => path.dirname(r).replace(options.src, ''));
      directories = unique(directories);

      for (var j = 0; j < directories.length; j++) {
        var dir = directories[j];
        var destDir = path.join(options.dest, dir);
        if (options.whatif) {
          console.log('mkdir -p ' + destDir);
          continue;
        }

        mkdirp.sync(destDir);
      }

      for (var j = 0; j < res.length; j++) {
        var s = res[j];
        var d = path.join(options.dest, s.replace(options.src, ''));

        if (options.verbose || options.whatif) {
          console.log('mv ' + s + ' ' + d);
        }
        if (options.whatif) { continue; }

        fs.renameSync(s, d);
      }
    }
  });

}