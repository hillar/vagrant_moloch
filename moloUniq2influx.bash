#!/bin/bash

# get unique.txt for fields
# calculate stats on count vector
# send result to influxdb

DEBUG="0"
MOLO="192.168.10.11:8005"
INFLUX="192.168.10.12:8086"
#url encoded filter
#EXPRESSION="expression=databytes.src%3E0%26%26databytes.dst%3E0"
EXPRESSION=""
FIELDS="a2 a1 p1 p2 pa sl db dns.status-term tlsja3-term fb1 fb2"
# 'timings' in seconds
WINDOW="120"
OVERLAP="60"
WAITFORELASTIC="90"
MOLOTIMEOUT="2"

# startTime & stopTime are from now()
STOP=$WAITFORELASTIC
START=$((WINDOW+STOP))
# time for one roundtrip
INTERVAL=$(((WINDOW-OVERLAP)))

echo "$(date) INFO: starting with window $WINDOW overlap $OVERLAP elawait $WAITFORELASTIC molotimeout $MOLOTIMEOUT fields $FIELDS expression $EXPRESSION "
while true
do
 vlan="dummy"
 #for vlan in 89 88
 #do
  timer_start=$(date +%s)
  end=$(date --date="$STOP seconds ago" +%s)
  start=$(date --date="$START seconds ago" +%s)
  time=$(echo "startTime=$start&stopTime=$end")
  data=""
  nodata=""
  for field in $FIELDS
  do
    #URL="http://localhost:8005/unique.txt?$time&expression=databytes.src%3E0%26%26databytes.dst%3E0%26%26vlan%3D$vlan&field=$field&counts=1"
    URL="http://$MOLO/unique.txt?$time&$EXPRESSION&field=$field&counts=1"
    [[ $DEBUG -gt 0 ]] && echo $URL
    curl -m $MOLOTIMEOUT -s --digest -uadmin:admin $URL > $vlan.$field.txt
    molook=$?
    [[ $molook -eq 0 ]] || echo "$(date) ERROR: moloch ($(MOLO)) did not respond in $MOLOTIMEOUT"
    [[ $molook -eq 0 ]] || break
    # send beartbeat
    mololines=$(wc -l $vlan.$field.txt | cut -f1 -d" ")
    # see https://docs.influxdata.com/influxdb/v1.3/guides/writing_data/#writing-data-using-the-http-api
    curl -s -m $MOLOTIMEOUT -XPOST "http://$INFLUX/write?db=molouniqs&precision=s" --data-binary "_heartbeat_,field=$field,vlan=$vlan value=$mololines $(date +%s)"
    influxok=$?
    [[ $influxok -eq 0 ]] || echo "$(date) ERROR: Influxdb ($INFLUX) did not respond in $MOLOTIMEOUT"
    # do somestats ...
    observationtime=$(date --date="$START seconds ago" +%s)
    rm $vlan.$field.stats
    touch $vlan.$field.stats
    [[ $mololines -gt 0 ]] && data="$data$field;"
    [[ $mololines -gt 0 ]] || nodata="$nodata$field;"
    # calculate single number values of vector
    # see https://github.com/hillar/atoll.js
    #                         take counts only
    [[ $mololines -gt 0 ]] && cut -f2 -d, $vlan.$field.txt | node vectorstats.js > $vlan.$field.stats
    statslines=$(wc -l $vlan.$field.stats | cut -f1 -d" ")
    [[ $DEBUG -gt 0 ]] && echo  "$vlan $field $mololines $statslines"
    #[[ $statslines -eq 0 ]] ||
    cat $vlan.$field.stats | while read line; do
      # see https://docs.influxdata.com/influxdb/v1.3/guides/writing_data/#writing-points-from-a-file
      echo $line | awk '{print $1 ",field='$field' value=" $2 " '$observationtime'"}';
    done | curl -s -m $MOLOTIMEOUT -XPOST "http://$INFLUX/write?db=molouniqs&precision=s" --data-binary @-
    influxok=$?
    [[ $influxok -eq 0 ]] || echo "$(date) ERROR: Influxdb ($INFLUX) did not respond in $MOLOTIMEOUT"
    sleep 1
  done
  timer_end=$(date +%s)
  timespent=$((timer_end-timer_start))
  echo "$(date) INFO: took $timespent sleep $((INTERVAL-timespent)) data:$data no data:$nodata "
  #check timespent is not more than interval
  [[ $((INTERVAL-timespent)) -gt 0 ]] || echo "$(date) WARNING: quering moloch took ($timespent) longer than one round ($INTERVAL) !"
  [[ $((INTERVAL-timespent)) -gt 0 ]] && sleep $((INTERVAL-timespent))
 #done
done
