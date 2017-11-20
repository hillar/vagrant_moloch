// read vector from stdin
// apply standard stat functions what return single numeric value
// and write to stdout

var atoll = require('./atoll.js');

// make list of functions, what return single numeric value
function _atollNumericFunctions() {
  var ret = {};
  var obj = atoll([1, 2, 3, 4, 5, 6]);
  for (var prop in obj) {
    if (typeof(obj[prop]) === 'function') {
      try {
        var tmp = obj[prop]();
      } catch (err) {
        //noop
      } finally {
        if (typeof(tmp) === 'number') {
          ret[prop] = NaN;
        }
      }
    }
  }
  return ret;
}

var functions = _atollNumericFunctions();

// reading from stdin
var fs = require("fs");
fs.readFile("/dev/stdin", "utf8", function(error, contents) {
  var a = contents.split("\n");
  a.pop();
  if (a.length > 0) {
    var stat = atoll(a.map(Number), true);
    var measures = {}
    for (var f in functions) {
      var value = stat[f]();
      if (value != 0 && value != Infinity && value != -Infinity && !isNaN(value)) {
        console.log(f, value)
      }
    }
  }
});
