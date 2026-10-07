#!/bin/sh
# Print the spans of one recent frontend trace from Jaeger's v3 API (port-forwarded to 19686):
# service, span name and duration, in start order.
S=$(date -u -v-30M +%Y-%m-%dT%H:%M:%SZ); E=$(date -u -v+1M +%Y-%m-%dT%H:%M:%SZ)
curl -s "localhost:19686/api/v3/traces?query.service_name=frontend&query.start_time_min=$S&query.start_time_max=$E&query.search_depth=1" |
jq -r '
  [.result.resourceSpans[] | (.resource.attributes[] | select(.key=="service.name") | .value.stringValue) as $svc
   | .scopeSpans[].spans[] | {svc: $svc, trace: .traceId, name, start: (.startTimeUnixNano|tonumber),
     ms: (((.endTimeUnixNano|tonumber) - (.startTimeUnixNano|tonumber)) / 1e6)}]
  | sort_by(.start) | "trace \(.[0].trace)  (\(length) spans)", (.[] | "  \(.svc | . + "          " | .[0:10]) \(.name | . + "                    " | .[0:20]) \(.ms * 1000 | round / 1000) ms")'
