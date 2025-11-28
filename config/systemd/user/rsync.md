# Szablon systemd: rsync@.service — krótkie wyjaśnienie

Ten plik opisuje, jak działa szablon unitu `rsync@.service` używany do lustrzanej synchronizacji katalogów przez rsync.

## Gdzie leży i jak używać
- Plik (szablon): `~/.config/systemd/user/rsync@.service`
- Użycie: powołujesz instancję, np. `rsync@A-B.service` (oraz opcjonalnie `rsync@A-B.timer`).
- Zmienne konfiguracyjne instancji znajdują się w pliku env: `~/.config/rsync/<instancja>.env` (np. `~/.config/rsync/A-B.env`).

## Sekcje i dyrektywy
- `[Unit] Description=Generic rsync mirror %I`
  - Opis unitu z identyfikatorem instancji (np. `A-B`).
- `ConditionPathExists=%h/.config/rsync/%i.env`
  - Start tylko, gdy istnieje plik env dla danej instancji.

- `[Service] Type=oneshot`
  - Jednorazowe wykonanie zadania; unit kończy się po sukcesie/błędzie.

- `EnvironmentFile=%h/.config/rsync/%i.env`
  - Ładuje zmienne `SRC` (źródło) i `DST` (cel) z pliku env instancji.

- `ExecStart=/usr/bin/bash -lc '...'`
  - Uruchamiamy przez powłokę z kontrolą błędów i logowaniem:
    - `set -euxo pipefail` — tryb surowy: loguj kroki, przerwij przy błędach.
    - `: "${SRC:?missing SRC}"; : "${DST:?missing DST}"` — twarda walidacja, że zmienne są ustawione.
    - `echo "rsync from $SRC to $DST"` — krótki log do journala.
    - `/usr/bin/mkdir -p "$DST"` — upewnia się, że katalog docelowy istnieje.
    - `exec /usr/bin/flock -n /tmp/rsync-%i.lock /usr/bin/rsync -avh --delete --exclude=/.stversions/ "$SRC/" "$DST/"`
      - `flock` blokuje równoległe uruchomienia tej samej instancji.
      - `rsync -a` zachowuje uprawnienia, czasy, rekurencję; `-v` gadatliwy; `-h` czytelne rozmiary.
      - `--delete` usuwa w B to, czego nie ma w A (lustrzane odbicie).
      - `--exclude=/.stversions/` chroni katalog `B/.stversions` (tworzony np. przez Syncthing) przed usunięciem.
      - Ukośniki na końcu (`SRC/`, `DST/`) oznaczają: kopiuj zawartość `SRC` do `DST`.

## Placeholdery systemd
- `%i` / `%I` — identyfikator instancji (np. `A-B`); używany m.in. w nazwie locka i ścieżkach.
- `%h` — katalog domowy użytkownika (np. `/home/donald`).

## Plik env (przykład)
Plik: `~/.config/rsync/A-B.env`

```
SRC=/home/donald/.t4L
DST=/home/donald/Xanadu/BACKUP/t4L
```

Możesz utworzyć kolejne pary (np. `C-D.env`) i uruchamiać `rsync@C-D.service`/`rsync@C-D.timer`.

## Uruchamianie i logi
- Przeładowanie unitów: `systemctl --user daemon-reload`
- Start ręczny: `systemctl --user start rsync@A-B.service`
- Włączenie timera: `systemctl --user enable --now rsync@A-B.timer`
- Logi: `journalctl --user -eu rsync@A-B.service -n 100`

## Timer: rsync@.timer
- Plik: `~/.config/systemd/user/rsync@.timer` (użycie: `rsync@A-B.timer`).
- `Unit=rsync@%i.service` — timer uruchamia odpowiadającą usługę instancji (np. `A-B`).
- `OnBootSec=2m` — pierwszy start 2 min po starcie sesji użytkownika.
- `OnUnitActiveSec=15m` — kolejne uruchomienia co 15 minut od zakończenia poprzedniego.
- `AccuracySec=1m` — dopuszczalne odchylenie, grupuje wybudzenia.
- `Persistent=true` — nadrobi wywołania, które wypadły, gdy timer był wyłączony.
- (Opcjonalnie) `RandomizedDelaySec=2m` — losowe rozproszenie startów.

### Użycie timera
- Włącz: `systemctl --user enable --now rsync@A-B.timer`
- Podgląd: `systemctl --user status rsync@A-B.timer` lub `systemctl --user list-timers rsync@A-B.timer`
- Ręczny start usługi: `systemctl --user start rsync@A-B.service`

### Zmiana harmonogramu
- Co godzinę: ustaw `OnUnitActiveSec=1h`.
- Kalendarzowo: użyj `OnCalendar=*:0/15` (co 15 min) lub `OnCalendar=hourly`.
- Po zmianach: `systemctl --user daemon-reload && systemctl --user restart rsync@A-B.timer`

## Dalsza konfiguracja
- Dodatkowe wykluczenia można dodać rozszerzając polecenie rsync w szablonie lub (alternatywnie) wprowadzić zmienną w pliku env i użyć jej w `ExecStart` (np. `RSYNC_OPTS`).
