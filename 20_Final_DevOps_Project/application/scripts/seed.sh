#!/usr/bin/env bash
# Seed a month of sample expenses through the public API.
#   ./seed.sh http://localhost:3000            (compose, via the nginx proxy)
#   CURL_OPTS="--resolve spendboard.local:8080:127.0.0.1" ./seed.sh http://spendboard.local:8080   (k8s ingress)
set -euo pipefail
BASE="${1:-http://localhost:8000}"
post() { curl -fsS ${CURL_OPTS:-} -X POST -H 'Content-Type: application/json' -d "$1" "$BASE/api/expenses" >/dev/null && echo "  + $2"; }
echo "Seeding $BASE"
post '{"title":"October rent","amount":"14500","category":"RENT","payment_method":"NETBANKING","spent_on":"2026-10-01"}' "rent"
post '{"title":"BigBasket groceries","amount":"2340.75","category":"FOOD","payment_method":"UPI","spent_on":"2026-10-02"}' "groceries"
post '{"title":"Metro recharge","amount":"500","category":"TRANSPORT","payment_method":"UPI","spent_on":"2026-10-03"}' "metro"
post '{"title":"Electricity bill","amount":"1820","category":"UTILITIES","payment_method":"UPI","spent_on":"2026-10-04"}' "electricity"
post '{"title":"Dinner with team","amount":"1260.50","category":"FOOD","payment_method":"CARD","spent_on":"2026-10-05"}' "dinner"
post '{"title":"Movie tickets","amount":"640","category":"ENTERTAINMENT","payment_method":"CARD","spent_on":"2026-10-06"}' "movie"
post '{"title":"Pharmacy","amount":"385","category":"HEALTH","payment_method":"CASH","spent_on":"2026-10-07"}' "pharmacy"
