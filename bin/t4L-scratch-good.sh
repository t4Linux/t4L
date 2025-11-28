#!/usr/bin/env bash
set -euo pipefail

# KONFIG
TERM_CLASS="kitty"
TERM_TITLE="scratchpad"
HIDDEN_WS="name:_scratchpad_hidden"
WIN_W=1200
WIN_H=700

have_jq() { command -v jq >/dev/null 2>&1; }

# NEW: gdzie trzymamy stan (ostatnio aktywne okno per workspace)
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/scratchpad_state"
mkdir -p -- "$STATE_DIR"

# NEW: helpers
ws_state_file() { echo "$STATE_DIR/ws_${1}.last"; }
client_exists() {
  local addr="$1"
  [[ -z "$addr" ]] && return 1
  hyprctl clients -j | jq -e --arg a "$addr" '.[] | select(.address==$a)' >/dev/null 2>&1
}

# 1) Jeśli terminal nie działa → uruchom, pokaż i WYJDŹ (nie chowaj przy pierwszym razie)
if ! pgrep -fa "${TERM_CLASS}.*--title ${TERM_TITLE}" >/dev/null 2>&1; then
  ${TERM_CLASS} --title "${TERM_TITLE}" & disown

  # Czekaj aż okno się pojawi (max 2 sekundy)
  for _ in {1..20}; do
    sleep 0.1
    win_json=$(hyprctl clients -j | jq -c --arg t "${TERM_TITLE}" --arg c "${TERM_CLASS}" \
      '.[] | select(.title==$t) | select(.class==$c)')
    [[ -n "$win_json" ]] && break
  done

  # Upewnij się, że ma fokus
  hyprctl dispatch focuswindow title:"${TERM_TITLE}" || true

  if have_jq && [[ -n "$win_json" ]]; then
    win_addr=$(jq -r '.address' <<<"$win_json")
    hyprctl dispatch setfloating on address:"${win_addr}"
    hyprctl dispatch resizewindowpixel exact $WIN_W $WIN_H address:"${win_addr}"
    hyprctl dispatch centerwindow
  fi
  exit 0
fi

# 2) Dalej: toggle show/hide istniejącego okna
if ! have_jq; then
  # bez jq tylko pokaż
  hyprctl dispatch focuswindow title:"${TERM_TITLE}" || true
  exit 0
fi

win_json=$(hyprctl clients -j | jq -c --arg t "${TERM_TITLE}" --arg c "${TERM_CLASS}" \
  '.[] | select(.title==$t) | select(.class==$c)')

if [[ -z "${win_json}" ]]; then
  # nie znaleziono → spróbuj uruchomić i wyjść
  ${TERM_CLASS} --title "${TERM_TITLE}" & disown
  for _ in {1..20}; do
    sleep 0.1
    win_json=$(hyprctl clients -j | jq -c --arg t "${TERM_TITLE}" --arg c "${TERM_CLASS}" \
      '.[] | select(.title==$t) | select(.class==$c)')
    [[ -n "$win_json" ]] && break
  done

  # NEW: zapamiętaj bieżące okno zanim przejmiesz fokus (na wypadek ponownych toggle)
  active_ws_id=$(hyprctl activeworkspace -j | jq -r '.id')
  prev_win_addr=$(hyprctl activewindow -j | jq -r '.address // empty')
  echo -n "${prev_win_addr}" >"$(ws_state_file "${active_ws_id}")"

  hyprctl dispatch focuswindow title:"${TERM_TITLE}" || true

  if [[ -n "$win_json" ]]; then
    win_addr=$(jq -r '.address' <<<"$win_json")
    hyprctl dispatch setfloating on address:"${win_addr}"
    hyprctl dispatch resizewindowpixel exact $WIN_W $WIN_H address:"${win_addr}"
    hyprctl dispatch centerwindow
  fi
  exit 0
fi

win_addr=$(jq -r '.address' <<<"$win_json")
win_ws_id=$(jq -r '.workspace.id' <<<"$win_json")
active_ws_id=$(hyprctl activeworkspace -j | jq -r '.id')

# Jeśli okno jest na aktywnym WS → SCHOWAJ (przenieś na ukryty WS)
if [[ "${win_ws_id}" == "${active_ws_id}" ]]; then
  # NEW: przed schowaniem przywrócimy później fokus do ostatniego okna z pliku stanu
  hyprctl dispatch movetoworkspacesilent "${HIDDEN_WS}",address:"${win_addr}"

  # NEW: spróbuj przywrócić fokus do poprzednio używanego okna na tym WS
  state_file="$(ws_state_file "${active_ws_id}")"
  if [[ -f "$state_file" ]]; then
    prev_addr="$(cat "$state_file")"
    if client_exists "$prev_addr"; then
      hyprctl dispatch focuswindow address:"${prev_addr}" || true
    else
      # fallback gdy okno zniknęło
      hyprctl dispatch cyclenext || true
    fi
  else
    # brak historii → minimalny fallback
    hyprctl dispatch cyclenext || true
  fi
  exit 0
fi

# Jeśli okno jest gdzie indziej (w tym na ukrytym) → POKAŻ na bieżącym WS
# NEW: zanim pokażesz scratchpada, zapamiętaj, co jest teraz aktywne na tym WS
prev_win_addr=$(hyprctl activewindow -j | jq -r '.address // empty')
echo -n "${prev_win_addr}" >"$(ws_state_file "${active_ws_id}")"

hyprctl dispatch movetoworkspacesilent "${active_ws_id}",address:"${win_addr}"
hyprctl dispatch focuswindow address:"${win_addr}"
hyprctl dispatch setfloating on address:"${win_addr}"
hyprctl dispatch resizewindowpixel exact $WIN_W $WIN_H address:"${win_addr}"
hyprctl dispatch centerwindow
hyprctl dispatch bringactivetotop || true

