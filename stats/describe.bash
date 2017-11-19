#!/bin/bash
# This returns some basic Descriptive Statistics


lines=""
while read line
do
  lines="$lines$line\n"
done < "${1:-/dev/stdin}"

#do some simple cleanup
lines=$(echo -e "$lines" | grep "^[0-9]")

# count lines
size=$(echo -e "$lines" | wc -l)
# exit if there is no lines
[[ $size -lt 1 ]] && exit

echo "size $size"
echo "min $(echo -e "$lines" | sort | head -1)"
echo "max $(echo -e "$lines" | sort -nr | head -1)"
sigma=$(echo -e "$lines" | awk '{ sum += $1; } END{ print( sum ); }')
echo "sigma $sigma"
xbar=$(echo "scale=16;${sigma} / ${size}" | bc 2> /dev/null | sed 's/^\./0./')
# exit if there is no mean
[[ -z $xbar ]] && exit
echo "mean $xbar"

# to few lines for next, exit
[[ $size -lt 3 ]] && exit

# This is technically a Sample Central Moment (or assumed to be)
m4=$(echo -e "$lines" | awk '{ sum += ( $1 - '${xbar}' ) ^ 4 } END{ printf("%.16f\n", (sum / NR) ) }')
m3=$(echo -e "$lines" | awk '{ sum += ( $1 - '${xbar}' ) ^ 3 } END{ printf("%.16f\n", (sum / NR) ) }')
m2=$(echo -e "$lines" | awk '{ sum += ( $1 - '${xbar}' ) ^ 2 } END{ printf("%.16f\n", (sum / NR) ) }')
m1=$(echo -e "$lines" | awk '{ sum += ( $1 - '${xbar}' ) ^ 1 } END{ printf("%.16f\n", (sum / NR) ) }')
#[[ $m1 -ne 0 ]] && "echo centralmoment $m1"

#variance
variance=$(echo "scale=16;( ${m2} / (${size} - 1) )" | bc 2> /dev/null | sed 's/^\./0./')
[[ -z $variance ]] || echo "variance $variance"
#kurtosis
kurtosisPop=$(echo "scale=16;${m4} / ( ${m2} * ${m2} )" | bc 2> /dev/null | sed 's/^\./0./')
[[ -z $kurtosisPop ]] || echo "kurtosisPop $kurtosisPop"
gp2=$(echo "scale=16;${kurtosisPop} - 3" | bc 2> /dev/null | sed 's/^\./0./')
c1=$(echo "scale=16;(${size} - 1) / ((${size} - 2) * (${size} - 3))" | bc 2> /dev/null | sed 's/^\./0./')
gp=$(echo "scale=16;((${size} + 1) * ${gp2}) + 6" | bc 2> /dev/null | sed 's/^\./0./')
kurtosis=$(echo "scale=16;${c1} * ${gp}" | bc 2> /dev/null | sed 's/^\./0./')
[[ -z $kurtosis ]] || echo "kurtosis $kurtosis"

#skewness
skewnessPop=$(echo "scale=16; ${m3} / ( ${m2} ^ 3/2 )" | bc 2> /dev/null | sed 's/^\./0./')
[[ -z $skewnessPop ]] || echo "skewnessPop $skewnessPop"
c=$(echo "scale=16;sqrt(${size} * (${size}-1)) / (${size} - 2)" | bc 2> /dev/null | sed 's/^\./0./')
skewness=$(echo "scale=16;(${c} * ${skewnessPop})"| bc 2> /dev/null | sed 's/^\./0./')
[[ -z $skewness ]] || echo "skewness $skewness"
