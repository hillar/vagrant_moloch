// read mfield name as argument
// read datapoints from stdin
// calculate standard stat functions
// and send to influxdb
// sorry, influxdb is hardcoded

if (process.argv[2]) {
  tvlan = process.argv[2];
} else {
  console.error('missing vlan tag name');
  process.exit(1);
}
if (process.argv[3]) {
  tfield = process.argv[3];
} else {
  console.error('missing field tag name');
  process.exit(1);
}
//console.dir(mfield);
var atoll = require('./atoll.js');

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

const Influx = require('influx');
const influx = new Influx.InfluxDB({
  host: '192.168.10.12',
  database: 'molouniqs'
});
// reading from stdin
var fs = require("fs");
fs.readFile("/dev/stdin", "utf8", function(error, contents) {
  var a = contents.split("\n");
  a.pop();
  console.dir(a.length);
  if (a.length > 1) {
    var stat = atoll(a.map(Number), true);
    var measures = {}
    for (var f in functions) {
      var value = stat[f]();
      if (value != 0 && value != Infinity && value != -Infinity && !isNaN(value)) {
        measures[f] = stat[f]();
      }
    }

    console.dir(measures);
    influx.writeMeasurement('moloch_stats', [{
      tags: {
        vlan: tvlan,
        field: tfield
      },
      fields: measures
    }]).then(() => {
					console.dir(measures);
					return;
		}).catch(err => {
        console.error(`Encountered error while writing measurements: ${err.message}`);
      });;

    console.dir(influx)
  }
});
