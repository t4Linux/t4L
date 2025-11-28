#!/usr/bin/env bash
# kconf — podmiana tokena w kubeconfig dla prod/uat
# Usage:
#   ./kconf {prod|uat} <sha256~...>
#   ./kconf --dry-run {prod|uat} <sha256~...>
#
# Zmienne:
#   KUBECONFIG (opcjonalnie) — ścieżka do kubeconfig; domyślnie ~/.config/kube/config

set -euo pipefail

# --------- Konfiguracja środowisk -> nazwa usera w kubeconfig ----------
user_name_for_env() {
  case "$1" in
  prod) echo "artur.chmur/api-ocp-priv-plusnet:6443" ;;
  uat) echo "artur.chmur/api-ocp-privq-plusnet:6443" ;;
  *)
    echo "Nieznane środowisko: $1 (użyj prod|uat)" >&2
    exit 1
    ;;
  esac
}

# --------- Wykrywanie narzędzi ----------
have_cmd() { command -v "$1" >/dev/null 2>&1; }

is_yq_v4() {
  if have_cmd yq; then
    # Szukamy sygnatury mikefarah i wersji 4.x
    yq --version 2>/dev/null | grep -qi 'mikefarah' && yq --version | grep -q ' version 4'
  else
    return 1
  fi
}

# --------- Narzędzia pomocnicze ----------
mask_token() {
  # pokazujemy 'sha256~' + 4 znaki + '…' + 4 końcowe, jeśli wygląda jak sha256~
  local t="${1:-}"
  if [[ "$t" =~ ^sha256~.+$ ]]; then
    local core="${t#sha256~}"
    local start="${core:0:4}"
    local end="${core: -4}"
    echo "sha256~${start}…${end}"
  else
    # inny format – maskuj ogólnie
    local len=${#t}
    if ((len > 8)); then
      echo "${t:0:4}…${t: -4}"
    else
      echo "(${len} chars)"
    fi
  fi
}

get_current_token_yq() {
  local cfg="$1" name="$2"
  # -oy = JSON/YAML output; bierzemy czysty string
  yq -oy '.users[] | select(.name == "'"$name"'") | .user.token' "$cfg" 2>/dev/null | tr -d '\r'
}

get_current_token_kubectl() {
  local cfg="$1" name="$2"
  KUBECONFIG="$cfg" kubectl config view -o jsonpath='{.users[?(@.name=="'"$name"'")].user.token}' --raw 2>/dev/null || true
}

set_token_kubectl() {
  local cfg="$1" name="$2" token="$3"
  KUBECONFIG="$cfg" kubectl config set-credentials "$name" --token="$token" >/dev/null
}

set_token_yq() {
  local cfg="$1" name="$2" token="$3"
  # -i -y: in-place + YAML output
  yq -i -y '
    (.users[] | select(.name == "'"$name"'") | .user.token) = "'"$token"'"
  ' "$cfg"
}

# --------- Parsowanie argumentów ----------
DRY_RUN=0
ARGS=()
for a in "$@"; do
  case "$a" in
  --dry-run | -n) DRY_RUN=1 ;;
  *) ARGS+=("$a") ;;
  esac
done

if ((${#ARGS[@]} != 2)); then
  echo "Użycie: $0 [--dry-run] {prod|uat} <sha256~...>" >&2
  exit 1
fi

ENV_NAME="${ARGS[0]}"
NEW_TOKEN="${ARGS[1]}"

KCFG="${KUBECONFIG:-$HOME/.config/kube/config}"
if [[ ! -f "$KCFG" ]]; then
  echo "Nie znaleziono kubeconfig: $KCFG" >&2
  exit 1
fi

USER_NAME="$(user_name_for_env "$ENV_NAME")"

# --------- Wybór ścieżki: yq v4 -> kubectl ----------
USE="none"
if is_yq_v4; then
  USE="yq"
elif have_cmd kubectl; then
  USE="kubectl"
else
  echo "Brak odpowiednich narzędzi: zainstaluj 'yq' (mikefarah v4) lub 'kubectl'." >&2
  exit 1
fi

# --------- Odczyt obecnego tokena ----------
CURRENT_TOKEN=""
if [[ "$USE" == "yq" ]]; then
  CURRENT_TOKEN="$(get_current_token_yq "$KCFG" "$USER_NAME" || true)"
else
  CURRENT_TOKEN="$(get_current_token_kubectl "$KCFG" "$USER_NAME" || true)"
fi

if [[ -z "$CURRENT_TOKEN" ]]; then
  # Może user nie istnieje?
  # Sprawdźmy, czy w ogóle jest wpis dla users[].name
  if yq -e '.users[] | select(.name == "'"$USER_NAME"'")' "$KCFG" >/dev/null 2>&1 ||
    KUBECONFIG="$KCFG" kubectl config view -o jsonpath='{.users[?(@.name=="'"$USER_NAME"'")].name}' --raw 2>/dev/null | grep -q .; then
    echo "Ostrzeżenie: użytkownik '$USER_NAME' istnieje, ale brak/nieczytelny .user.token (może inny typ uwierzytelniania)." >&2
  else
    echo "Błąd: brak wpisu users[].name == '$USER_NAME' w $KCFG" >&2
    exit 1
  fi
fi

echo "Kubeconfig: $KCFG"
echo "Użytkownik : $USER_NAME"
echo "Stary token: $(mask_token "$CURRENT_TOKEN")"
echo "Nowy token : $(mask_token "$NEW_TOKEN")"
echo

if ((DRY_RUN)); then
  echo "[DRY-RUN] Nie wprowadzono zmian."
  exit 0
fi

# --------- Backup + zapis ----------
cp "$KCFG" "$KCFG.bak.$(date +%s)"
if [[ "$USE" == "yq" ]]; then
  set_token_yq "$KCFG" "$USER_NAME" "$NEW_TOKEN"
else
  set_token_kubectl "$KCFG" "$USER_NAME" "$NEW_TOKEN"
fi

# --------- Walidacja po zapisie ----------
POST_TOKEN=""
if [[ "$USE" == "yq" ]]; then
  POST_TOKEN="$(get_current_token_yq "$KCFG" "$USER_NAME" || true)"
else
  POST_TOKEN="$(get_current_token_kubectl "$KCFG" "$USER_NAME" || true)"
fi

if [[ "$POST_TOKEN" == "$NEW_TOKEN" ]]; then
  echo "OK ✅ Zaktualizowano token dla [$ENV_NAME] (user: $USER_NAME)."
else
  echo "❌ Aktualizacja nie powiodła się — przywróć backup: $KCFG.bak.*" >&2
  exit 1
fi
