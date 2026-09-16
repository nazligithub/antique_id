#!/bin/zsh
# Swap the weekly plan's introductory offer between a free trial and a paid one.
#
# An App Store subscription carries at most one introductory offer per
# territory, so this is always a delete followed by a create -- there is no way
# to edit the mode in place. Between the two calls the plan has no introductory
# offer at all, which is why this runs territory by territory and finishes in a
# couple of minutes rather than leaving the whole catalogue bare.
#
#   ./tools/switch_intro_offer.sh paid --dry-run
#   ./tools/switch_intro_offer.sh paid --confirm
#   ./tools/switch_intro_offer.sh free --confirm     # roll back
#
# The app reads whichever offer is live straight from StoreKit, so no release
# is needed on either side of this.

set -e

SUBSCRIPTION_ID="6753019907"      # Weekly Access -- com.mobinaz.antique.weekly
DURATION="ONE_WEEK"
CSV="$(dirname "$0")/paid_trial_offers.csv"

MODE="${1:-}"
FLAG="${2:---dry-run}"

if [[ "$MODE" != "paid" && "$MODE" != "free" ]]; then
  echo "usage: $0 {paid|free} [--dry-run|--confirm]" >&2
  exit 64
fi

if [[ "$MODE" == "paid" ]]; then
  OFFER_MODE="PAY_AS_YOU_GO"
  echo "→ 1 week, pay as you go at the local equivalent of \$0.99 (tier 10010)"
else
  OFFER_MODE="FREE_TRIAL"
  echo "→ 1 week, free trial"
fi

echo "→ subscription $SUBSCRIPTION_ID"
echo

echo "== current offers =="
asc subscriptions offers introductory list \
  --subscription-id "$SUBSCRIPTION_ID" --paginate 2>/dev/null \
  | python3 -c "
import json, sys
pages = json.load(sys.stdin)
data = pages['data'] if isinstance(pages, dict) else [x for p in pages for x in p['data']]
modes = {}
for o in data:
    a = o['attributes']
    modes[(a['offerMode'], a['duration'])] = modes.get((a['offerMode'], a['duration']), 0) + 1
for (m, d), n in modes.items():
    print(f'   {n:>4} x {m} / {d}')
print(f'   total {len(data)}')
"
echo

if [[ "$FLAG" != "--confirm" ]]; then
  echo "== what would be created (dry run) =="
  if [[ "$MODE" == "paid" ]]; then
    asc subscriptions offers introductory import \
      --subscription-id "$SUBSCRIPTION_ID" --input "$CSV" \
      --offer-duration "$DURATION" --offer-mode "$OFFER_MODE" \
      --number-of-periods 1 --dry-run --output table
  else
    asc subscriptions offers introductory create \
      --subscription-id "$SUBSCRIPTION_ID" --all-territories \
      --offer-duration "$DURATION" --offer-mode "$OFFER_MODE" \
      --number-of-periods 1 --dry-run --output table
  fi
  echo
  echo "Nothing was changed. Re-run with --confirm to apply."
  exit 0
fi

echo "== deleting the existing offers =="
asc subscriptions offers introductory list \
  --subscription-id "$SUBSCRIPTION_ID" --paginate 2>/dev/null \
  | python3 -c "
import json, sys
pages = json.load(sys.stdin)
data = pages['data'] if isinstance(pages, dict) else [x for p in pages for x in p['data']]
print('\n'.join(o['id'] for o in data))
" > /tmp/intro_offer_ids.txt

COUNT=$(wc -l < /tmp/intro_offer_ids.txt | tr -d ' ')
echo "   $COUNT offers to remove"
xargs -P 8 -I {} asc subscriptions offers introductory delete --id {} --confirm \
  < /tmp/intro_offer_ids.txt > /dev/null 2>&1 || true
echo "   done"
echo

echo "== creating the new offers =="
if [[ "$MODE" == "paid" ]]; then
  asc subscriptions offers introductory import \
    --subscription-id "$SUBSCRIPTION_ID" --input "$CSV" \
    --offer-duration "$DURATION" --offer-mode "$OFFER_MODE" \
    --number-of-periods 1 --confirm --output table
else
  asc subscriptions offers introductory create \
    --subscription-id "$SUBSCRIPTION_ID" --all-territories \
    --offer-duration "$DURATION" --offer-mode "$OFFER_MODE" \
    --number-of-periods 1 --output table
fi

echo
echo "== result =="
asc subscriptions offers introductory list \
  --subscription-id "$SUBSCRIPTION_ID" --paginate 2>/dev/null \
  | python3 -c "
import json, sys
pages = json.load(sys.stdin)
data = pages['data'] if isinstance(pages, dict) else [x for p in pages for x in p['data']]
modes = {}
for o in data:
    a = o['attributes']
    modes[(a['offerMode'], a['duration'])] = modes.get((a['offerMode'], a['duration']), 0) + 1
for (m, d), n in modes.items():
    print(f'   {n:>4} x {m} / {d}')
print(f'   total {len(data)}')
"
