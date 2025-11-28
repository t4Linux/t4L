#!/usr/bin/env bash
set -euo pipefail

# --- ustawienia ---
STATE="${HOME}/.cache/crypto-currency"
API="https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd,pln&include_24hr_change=true"

# --- helpers (bez locale) ---
round0() { awk -v v="$1" 'BEGIN{printf("%.0f", v)}'; }
commas() { # wstawia przecinki 1,234,567 dla liczby całkowitej
  local n="$(round0 "$1")" sign="" s out=""
  [[ $n == -* ]] && sign="-" && n="${n#-}"
  s="$n"
  while ((${#s} > 3)); do
    out=","${s: -3}"${out}"
    s="${s:0:${#s}-3}"
  done
  echo "${sign}${s}${out}"
}
fmt_pln() { printf "%s zł" "$(commas "$1")"; }
fmt_usd() { printf "\$%s"   "$(commas "$1")"; }

is_pos() { awk -v v="$1" 'BEGIN{exit !(v>=0)}'; }
is_neg() { awk -v v="$1" 'BEGIN{exit !(v<0)}'; }
arrow()  { is_pos "$1" && echo "▲" || echo "▼"; }
cls() {
  if is_pos "$1" && is_pos "$2"; then echo "up"
  elif is_neg "$1" && is_neg "$2"; then echo "down"
  else echo "mixed"; fi
}
round1() { awk -v v="$1" 'BEGIN{printf("%.1f", v)}'; }

# --- stan waluty (scroll) ---
mkdir -p "$(dirname "$STATE")"
[[ -f "$STATE" ]] || echo pln > "$STATE"
CCY="$(cat "$STATE" 2>/dev/null || echo pln)"

# --- pobranie danych ---
JSON="$(curl -fsSL --max-time 5 "$API" 2>/dev/null || true)"
if [[ -z "$JSON" ]] || ! jq -e . >/dev/null 2>&1 <<<"$JSON"; then
  jq -nc --arg text "₿ ?  Ξ ?" --arg tip "Brak danych (API)" --arg class "down" \
    '{text:$text, tooltip:$tip, class:$class}'
  exit 0
fi

btc_pln=$(jq -r '.bitcoin.pln' <<<"$JSON")
eth_pln=$(jq -r '.ethereum.pln' <<<"$JSON")
btc_usd=$(jq -r '.bitcoin.usd' <<<"$JSON")
eth_usd=$(jq -r '.ethereum.usd' <<<"$JSON")
btc_chg=$(jq -r '.bitcoin.usd_24h_change' <<<"$JSON")
eth_chg=$(jq -r '.ethereum.usd_24h_change' <<<"$JSON")

if [[ "$CCY" == "usd" ]]; then
  BTC="$(fmt_usd "$btc_usd")"; ETH="$(fmt_usd "$eth_usd")"; CURR="USD"
else
  BTC="$(fmt_pln "$btc_pln")"; ETH="$(fmt_pln "$eth_pln")"; CURR="PLN"
fi

btc_sign=$(arrow "$btc_chg")
eth_sign=$(arrow "$eth_chg")
klass=$(cls "$btc_chg" "$eth_chg")

TEXT="₿ ${BTC} ${btc_sign}  Ξ ${ETH} ${eth_sign}"
TOOLTIP=$(printf "BTC: %s  (24h: %s%%)\nETH: %s  (24h: %s%%)\nWaluta: %s" \
          "$BTC" "$(round1 "$btc_chg")" "$ETH" "$(round1 "$eth_chg")" "$CURR")

jq -nc --arg text "$TEXT" --arg tip "$TOOLTIP" --arg class "$klass" \
  '{text:$text, tooltip:$tip, class:$class}'
