#!/bin/bash

curl http://localhost:9200

/data/moloch-nightly/bin/moloch-capture -c /data/moloch-nightly/etc/config.ini
