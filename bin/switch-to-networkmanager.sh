#!/usr/bin/env bash
set -euo pipefail

### USTAWIENIA
PURGE_OLD=0
ASSUME_YES=0
WIFI_BACKEND=""

usage() {
  cat <<USAGE
Użycie: sudo $(basename "$0") [--yes] [--purge] [--wifi-backend=iwd|wpa]

  --yes                 pomiń pytania (działaj nieinteraktywnie)
  --purge               odinstaluj stare pakiety (dhcpcd, netctl, wicd) po przełączeniu
  --wifi-backend=...    wymuś backend Wi-Fi dla NM: iwd lub wpa
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --yes) ASSUME_YES=1 ;;
    --purge) PURGE_OLD=1 ;;
    --wifi-backend=iwd) WIFI_BACKEND="iwd" ;;
    --wifi-backend=wpa) WIFI_BACKEND="wpa" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Nieznana flaga: $arg"; usage; exit 1 ;;
  esac
done

# --- sprawdź root
if [[ $EUID -ne 0 ]]; then
  echo "Uruchom jako root (sudo)." >&2
  exit 1
fi

# --- sprawdź pacman
if ! command -v pacman >/dev/null 2>&1; then
  echo "To nie wygląda na system oparty o pacman (Arch/Omarchy?)." >&2
  exit 1
fi

confirm() {
  local msg="$1"
  if [[ $ASSUME_YES -eq 1 ]]; then
    return 0
  fi
  read -r -p "$msg [t/N]: " ans
  [[ "${ans,,}" == "t" || "${ans,,}" == "tak" || "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
}

ts="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="/etc/old_network_backup_${ts}"
mkdir -p "$BACKUP_DIR"

echo "==> Wykrywanie potencjalnie kolidujących usług…"
mapfile -t CANDIDATES < <(systemctl list-unit-files --no-legend | awk '{print $1}' | grep -E '^(systemd-networkd|dhcpcd|netctl|wicd).*$' || true)

SERVICES_TO_DISABLE=(
  systemd-networkd.service
  systemd-networkd.socket
  systemd-networkd-wait-online.service
  dhcpcd.service
  wicd.service
)

# netctl może mieć instancje netctl-auto@
mapfile -t NETCTL_INSTANCES < <(systemctl list-units --type=service --no-legend | awk '{print $1}' | grep -E '^netctl(-auto@.*)?\.service$' || true)
SERVICES_TO_DISABLE+=("${NETCTL_INSTANCES[@]}")

echo "==> Usługi do sprawdzenia/wyłączenia:"
printf '   - %s\n' "${SERVICES_TO_DISABLE[@]}" | sed '/^   - $/d' || true

if confirm "Wyłączyć i zatrzymać powyższe usługi oraz przejść na NetworkManagera?"; then
  for svc in "${SERVICES_TO_DISABLE[@]}"; do
    [[ -z "$svc" ]] && continue
    if systemctl list-unit-files | grep -q "^${svc}\b"; then
      echo " -> disable --now $svc"
      systemctl disable --now "$svc" || true
      # na wszelki wypadek zmaskuj znane kolidujące
      if [[ "$svc" =~ ^systemd-networkd ]]; then
        systemctl mask systemd-networkd.service systemd-networkd.socket systemd-networkd-wait-online.service || true
      fi
    fi
  done
else
  echo "Przerwano na prośbę użytkownika."
  exit 1
fi

echo "==> Backup starych konfiguracji do: $BACKUP_DIR"
for path in /etc/systemd/network /etc/netctl /etc/dhcpcd.conf; do
  if [[ -e "$path" ]]; then
    echo " -> przenoszę $path -> $BACKUP_DIR/"
    mv "$path" "$BACKUP_DIR/" || true
  fi
done

# utwórz puste katalogi, by nie zostawić martwych ścieżek w systemd
[[ -d /etc/systemd ]] && mkdir -p /etc/systemd/network
mkdir -p /etc/NetworkManager/conf.d

echo "==> Instalacja NetworkManager…"
pacman -Sy --needed --noconfirm networkmanager || { echo "Błąd instalacji networkmanager"; exit 1; }

# Przydatne narzędzia
EXTRAS=(nm-connection-editor nmtui network-manager-applet)
for pkg in "${EXTRAS[@]}"; do
  pacman -S --needed --noconfirm "$pkg" || true
done

# Opcjonalny backend Wi-Fi
if [[ -n "$WIFI_BACKEND" ]]; then
  echo "==> Konfiguruję backend Wi-Fi NM: $WIFI_BACKEND"
  cat > /etc/NetworkManager/conf.d/wifi-backend.conf <<CFG
[device]
wifi.backend=$WIFI_BACKEND
CFG
  # iwd potrzebuje pakietu i usługi (NM używa iwd jako biblioteki – nie trzeba usługi iwd.service, ale pakiet iwd bywa wymagany)
  if [[ "$WIFI_BACKEND" == "iwd" ]]; then
    pacman -S --needed --noconfirm iwd || true
    # Upewnij się, że wpa_supplicant nie jest wymuszony przez inne usługi
    systemctl disable --now wpa_supplicant.service 2>/dev/null || true
  fi
fi

# Upewnij się, że NM zarządza interfejsami
echo "==> Upewniam się, że NM zarządza interfejsami…"
cat > /etc/NetworkManager/NetworkManager.conf <<'NMCONF'
[main]
plugins=keyfile

[ifupdown]
managed=true
NMCONF

echo "==> Włączam i uruchamiam NetworkManager…"
systemctl enable --now NetworkManager.service

# krótki wait, by urządzenia się pojawiły
sleep 2

echo "==> Status NetworkManager:"
systemctl --no-pager status NetworkManager || true

echo "==> Urządzenia wg nmcli:"
nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status || true

if [[ $PURGE_OLD -eq 1 ]]; then
  echo "==> Usuwam stare pakiety (dhcpcd, netctl, wicd)…"
  pacman -Rns --noconfirm dhcpcd netctl wicd 2>/dev/null || true
fi

echo
echo "✅ Gotowe."
echo "Backup starych konfiguracji: $BACKUP_DIR"
echo
echo "Przydatne:"
echo "  - nmtui               # prosta konfiguracja w TUI"
echo "  - nmcli dev wifi list # pokaż sieci Wi-Fi"
echo "  - nmcli dev wifi connect \"SSID\" password \"HASLO\""
echo "  - (opcjonalnie) nm-applet &  # w autostarcie środowiska graficznego"
