#!/bin/sh
# Run a PromQL instant query against Prometheus (port-forwarded to 19090) and print one line per series.
# usage: ./promql.sh '<query>'
curl -s --get --data-urlencode "query=$1" http://localhost:19090/api/v1/query |
  jq -r '.data.result[] | "\(.metric | del(.__name__) | to_entries | map("\(.key)=\(.value)") | join(" "))  =>  \(.value[1])"'
