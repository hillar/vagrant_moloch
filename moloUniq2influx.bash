
while true
do
 vlan="dummy"
 #for vlan in 89 82 81 73 83 88 85 100 71
 #do
  for field in a2 a1 p1 p2 pa sl db
  do
  echo "$vlan $field"
  end=$(date --date='2 minutes ago' +%s)
  start=$(date --date='120 minutes ago' +%s)
  time=$(echo "startTime=$start&stopTime=$end")
  #URL="http://localhost:8005/unique.txt?$time&expression=databytes.src%3E0%26%26databytes.dst%3E0%26%26vlan%3D$vlan&field=$field&counts=1"
URL="http://192.168.10.11:8005/unique.txt?$time&expression=databytes.src%3E0%26%26databytes.dst%3E0&field=$field&counts=1"
  echo $URL
  curl -m 2 -s --digest -uadmin:admin $URL > $vlan.$field.txt
  [ $? -eq 0 ] || break
  vl=$(wc -l $vlan.$field.txt | cut -f1 -d" ")
  #[ $vl -eq 0 ] || break
  cut -f2 -d, $vlan.$field.txt | node moloUniq2influx.js $vlan $field
  sleep 1
  done
  sleep 30
 #done
done
